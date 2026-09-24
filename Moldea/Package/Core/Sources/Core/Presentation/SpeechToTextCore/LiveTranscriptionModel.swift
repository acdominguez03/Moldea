//
//  LiveTranscriptionModel.swift
//  Core
//
//  Created by Andrés on 19/09/2026.
//

import Foundation
import Speech
import AVFoundation
import SwiftUI

@MainActor
@Observable
final class LiveTranscriptionModel {
    private(set) var finalizedText = "" {
        didSet { refreshStyledTranscript() }
    }
    
    private(set) var volatileText = "" {
        didSet { refreshStyledTranscript() }
    }
    
    private(set) var styledTranscript = AttributedString()
    
    private(set) var phase: TranscriptionPhaseEnum = .idle
    
    //Progreso de la descarga del modelo
    private(set) var downloadProgress: Progress?
    
    var isTranscribing: Bool { phase == .transcribing }
    var isPreparing: Bool { phase == .preparing }
    var hasTranscript: Bool { !finalizedText.isEmpty || !volatileText.isEmpty }
    
    var transcript: String {
        (finalizedText + volatileText)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
    
    private var analyzer: SpeechAnalyzer?
    private var audioEngine: AVAudioEngine?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var captureSession: AVCaptureSession?
    
    // `CaptureInputSequenceProvider` es de iOS 27 asi que se guarda como AnyObject
    private var captureProvider: AnyObject?
    private var sessionTask: Task<Void, Never>?
    private var resultsTask: Task<Void, Never>?
    
    func toggleTranscribing() {
        switch phase {
        case .transcribing:
            stopTranscribing()
        case .preparing:
            break
        case .idle, .failed:
            startTranscribing()
        }
    }
    
    func startTranscribing() {
        guard sessionTask == nil else { return }
        
        finalizedText = ""
        volatileText = ""
        phase = .preparing
        
        sessionTask = Task {
            do {
                try await runSession()
            } catch is CancellationError {
                // Expected when the session is stopped.
            } catch {
                print("Session failed: \(String(describing: error))")
                phase = .failed(Self.message(for: error))
            }
            await tearDown()
        }
    }
    
    func stopTranscribing() {
        guard phase == .transcribing else { return }
        phase = .idle
        
        stopEngine()
        stopCaptureSession()
        inputBuilder?.finish()
        inputBuilder = nil
    }
    
    func finishTranscribing() async {
        switch phase {
        case .transcribing:
            stopTranscribing()
        case .preparing:
            sessionTask?.cancel()
        case .idle, .failed:
            break
        }
        
        await sessionTask?.value
    }
    
#if targetEnvironment(simulator)
    private static let isSimulator = true
#else
    private static let isSimulator = false
#endif
    
#if DEBUG
    private static func samplePhrase() -> String { HabitCommandSamples.nextPhrase() }
#else
    private static func samplePhrase() -> String { "" }
#endif
    
    private func runSession() async throws {
        if Self.isSimulator {
            finalizedText = Self.samplePhrase()
            return
        }
        
        guard AVAudioApplication.shared.recordPermission == .granted else {
            throw TranscriptionErrorEnum.microphoneNotAuthorized
        }
        let transcriber = try await run(.deviceSupport) {
            try await Self.makeTranscriber()
        }
        try await installAssets(for: transcriber.module)
        
#if compiler(>=6.3)
        if #available(iOS 27, *) {
            try await analyzeCaptureSession(transcriber: transcriber)
        }
#else
        try await analyzeAudioEngine(transcriber: transcriber)
#endif
        
        try await analyzeAudioEngine(transcriber: transcriber)
    }
    
#if compiler(>=6.3)
    @available(iOS 27, *)
    private func analyzeCaptureSession(transcriber: TranscriberEnum) async throws {
        let provider = try await run(.audioEngine) {
            try await Self.makeCaptureProvider(for: transcriber.module)
        }
        captureProvider = provider
        captureSession = provider.captureSession
        
        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber.module]
        ) else {
            throw TranscriptionErrorEnum.stageFailed(.audioFormat, TranscriptionErrorEnum.noCompatibleAudioFormat)
        }
        print("Analyzer format: \(String(describing: analyzerFormat))")
        
        let analyzer = try await prepareAnalyzer(for: transcriber, format: analyzerFormat)
        observeResults(of: transcriber)
        
        let inputSequence = provider.analyzerInputs
        provider.captureSession.startRunning()
        phase = .transcribing
        
        try await analyze(inputSequence, with: analyzer)
    }
#endif
    
    // Funcionalidad de iOS 26: motor de audio con tap y conversión manual de buffers.
    private func analyzeAudioEngine(transcriber: TranscriberEnum) async throws {
        let engine = try run(.audioEngine) {
            try makeEngine()
        }
        
        audioEngine = engine
        
        let recordingFormat = engine.inputNode.outputFormat(forBus: 0)
        print("Microphone format: \(String(describing: recordingFormat))")
        
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw TranscriptionErrorEnum.stageFailed(.audioEngine, TranscriptionErrorEnum.invalidAudioFormat)
        }
        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber.module],
            considering: recordingFormat
        ) else {
            throw TranscriptionErrorEnum.stageFailed(.audioFormat, TranscriptionErrorEnum.noCompatibleAudioFormat)
        }
        print("Analyzer format: \(String(describing: analyzerFormat))")
        
        let analyzer = try await prepareAnalyzer(for: transcriber, format: analyzerFormat)
        observeResults(of: transcriber)
        
        let (inputSequence, inputBuilder) = AsyncStream.makeStream(of: AnalyzerInput.self)
        self.inputBuilder = inputBuilder
        try run(.audioEngine) {
            try Self.startEngine(engine, feeding: inputBuilder, recordingFormat: recordingFormat, analyzerFormat: analyzerFormat)
        }
        phase = .transcribing
        
        try await analyze(inputSequence, with: analyzer)
    }
    
#if compiler(>=6.3)
    @available(iOS 27, *)
    @concurrent
    private nonisolated static func makeCaptureProvider(
        for module: any SpeechModule
    ) async throws -> sending CaptureInputSequenceProvider {
        guard let captureDevice = AVCaptureDevice.default(.microphone, for: .audio, position: .unspecified) else {
            throw TranscriptionErrorEnum.microphoneUnavailable
        }
        return try await CaptureInputSequenceProvider.providerWithSession(
            from: captureDevice,
            compatibleWith: [module]
        )
    }
#endif
    
    private func prepareAnalyzer(for transcriber: TranscriberEnum, format: AVAudioFormat) async throws -> SpeechAnalyzer {
        let analyzer = SpeechAnalyzer(
            modules: [transcriber.module],
            options: SpeechAnalyzer.Options(priority: .userInitiated, modelRetention: .lingering)
        )
        self.analyzer = analyzer
        
        try await run(.analysis) {
            try await analyzer.prepareToAnalyze(in: format)
        }
        return analyzer
    }
    
    private func analyze<InputSequence>(
        _ inputSequence: InputSequence,
        with analyzer: SpeechAnalyzer
    ) async throws where InputSequence: Sendable & AsyncSequence, InputSequence.Element == AnalyzerInput {
        try await run(.analysis) {
            let lastSampleTime = try await analyzer.analyzeSequence(inputSequence)
            if let lastSampleTime {
                try await analyzer.finalizeAndFinish(through: lastSampleTime)
            } else {
                await analyzer.cancelAndFinishNow()
            }
        }
    }
    
    private func observeResults(of transcriber: TranscriberEnum) {
        resultsTask = Task { [weak self] in
            do {
                switch transcriber {
                case .speech(let module):
                    for try await result in module.results {
                        self?.apply(text: result.text, isFinal: result.isFinal)
                    }
                case .dictation(let module):
                    for try await result in module.results {
                        self?.apply(text: result.text, isFinal: result.isFinal)
                    }
                }
            } catch is CancellationError {
                // The session was ended before the stream drained; not a failure.
            } catch {
                print("Results stream failed: \(String(describing: error))")
                self?.phase = .failed(Self.message(for: error))
            }
        }
    }
    
    private nonisolated static var candidateLocales: [Locale] {
        var seen = Set<String>()
        return (Locale.preferredLanguages.map(Locale.init(identifier:)) + [.current])
            .filter { seen.insert($0.identifier).inserted }
    }
    
    private nonisolated static func makeTranscriber() async throws -> TranscriberEnum {
        let candidates = candidateLocales
        print("Candidate locales: \(candidates.map(\.identifier).joined(separator: ", "))")
        
        if SpeechTranscriber.isAvailable {
            for candidate in candidates {
                if let locale = await SpeechTranscriber.supportedLocale(equivalentTo: candidate) {
                    print("Using SpeechTranscriber with locale \(locale.identifier)")
                    return .speech(SpeechTranscriber(locale: locale, preset: .progressiveTranscription))
                }
            }
        }
        
        for candidate in candidates {
            if let locale = await DictationTranscriber.supportedLocale(equivalentTo: candidate) {
                print("Using DictationTranscriber with locale \(locale.identifier)")
                return .dictation(DictationTranscriber(locale: locale, preset: .progressiveLongDictation))
            }
        }
        
        throw TranscriptionErrorEnum.localeNotSupported
    }
    
    // Downloads the speech models on demand, reporting progress to the UI.
    private func installAssets(for module: any SpeechModule) async throws {
        let status = await AssetInventory.status(forModules: [module])
        print("Asset status: \(String(describing: status))")
        
        guard status != .installed else { return }
        guard status != .unsupported else {
            throw TranscriptionErrorEnum.stageFailed(.assets, TranscriptionErrorEnum.transcriptionUnavailable)
        }
        
        try await run(.assets) {
            guard let request = try await AssetInventory.assetInstallationRequest(supporting: [module]) else {
                return
            }
            downloadProgress = request.progress
            defer { downloadProgress = nil }
            try await request.downloadAndInstall()
        }
    }
    
    private func makeEngine() throws -> AVAudioEngine {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement)
        try audioSession.setActive(true)
        return AVAudioEngine()
    }
    
    private nonisolated static func startEngine(
        _ engine: AVAudioEngine,
        feeding inputBuilder: AsyncStream<AnalyzerInput>.Continuation,
        recordingFormat: AVAudioFormat,
        analyzerFormat: AVAudioFormat
    ) throws {
        let converter: AVAudioConverter?
        if recordingFormat.isEqual(analyzerFormat) {
            converter = nil
            print("Microphone format matches the analyzer; skipping conversion")
        } else {
            guard let made = AVAudioConverter(from: recordingFormat, to: analyzerFormat) else {
                throw TranscriptionErrorEnum.audioConversionFailed
            }
            converter = made
        }
        
        engine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { buffer, _ in
            guard let converter else {
                inputBuilder.yield(AnalyzerInput(buffer: buffer))
                return
            }
            guard let converted = Self.convert(buffer, using: converter) else { return }
            inputBuilder.yield(AnalyzerInput(buffer: converted))
        }
        
        engine.prepare()
        try engine.start()
    }
    
    private nonisolated static func convert(
        _ buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter
    ) -> AVAudioPCMBuffer? {
        guard buffer.format.isEqual(converter.inputFormat) else { return nil }
        
        let format = converter.outputFormat
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up))
        guard capacity > 0,
              let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            return nil
        }
        
        var consumed = false
        var conversionError: NSError?
        let status = converter.convert(to: output, error: &conversionError) { _, inputStatus in
            if consumed {
                inputStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            inputStatus.pointee = .haveData
            return buffer
        }
        
        if status == .error {
            print("Audio conversion failed: \(String(describing: conversionError))")
            return nil
        }
        return output.frameLength > 0 ? output : nil
    }
    
    // Runs one step of the session, tagging any failure with the step that produced it.
    private func run<T>(_ stage: StageEnum, _ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as TranscriptionErrorEnum {
            throw error
        } catch {
            print("\(stage.rawValue) failed: \(String(describing: error))")
            throw TranscriptionErrorEnum.stageFailed(stage, error)
        }
    }
    
    private func run<T>(_ stage: StageEnum, _ work: () throws -> T) throws -> T {
        do {
            return try work()
        } catch let error as TranscriptionErrorEnum {
            throw error
        } catch {
            print("\(stage.rawValue) failed: \(String(describing: error))")
            throw TranscriptionErrorEnum.stageFailed(stage, error)
        }
    }
    
    private nonisolated static func message(for error: any Error) -> LocalizedStringResource {
        (error as? TranscriptionErrorEnum)?.message ?? CoreTextsEnum.genericError
    }
    
    private func apply(text: AttributedString, isFinal: Bool) {
        let plainText = String(text.characters)
        
        if isFinal {
            finalizedText += plainText
            volatileText = ""
        } else {
            volatileText = plainText
        }
    }
    
    private func refreshStyledTranscript() {
        var text = AttributedString(finalizedText)
        var volatile = AttributedString(volatileText)
        volatile.foregroundColor = .secondary
        text.append(volatile)
        styledTranscript = text
    }
    
    private func stopEngine() {
        guard let audioEngine else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        self.audioEngine = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    private func stopCaptureSession() {
        guard let captureSession else { return }
        captureSession.stopRunning()
        self.captureSession = nil
        captureProvider = nil
    }
    
    private func tearDown() async {
        await resultsTask?.value
        resultsTask = nil
        sessionTask = nil
        downloadProgress = nil
        stopEngine()
        stopCaptureSession()
        inputBuilder?.finish()
        inputBuilder = nil
        analyzer = nil
        
        if phase == .transcribing || phase == .preparing {
            phase = .idle
        }
    }
}
