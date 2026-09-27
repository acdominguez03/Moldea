//
//  SpeechToTextViewModel.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

import Foundation

@Observable
@MainActor
final class SpeechToTextViewModel {
    private(set) var isFinishing = false
    private(set) var isPresentingCommand = false
    private(set) var transcriptForAI = ""
    private(set) var commandViewModel: HabitCommandViewModel?

    private let parser: any HabitCommandParsing
    private let makeCommandViewModel: @MainActor () -> HabitCommandViewModel

    private let transcription = LiveTranscriptionModel()

    var phase: TranscriptionPhaseEnum { transcription.phase }
    var downloadProgress: Progress? { transcription.downloadProgress }
    var styledTranscript: AttributedString { transcription.styledTranscript }
    var hasTranscript: Bool { transcription.hasTranscript }
    var isTranscribing: Bool { transcription.isTranscribing }
    var canFinish: Bool { !isFinishing }
    var canClose: Bool { !transcription.isPreparing && !isFinishing }

    init(
        parser: any HabitCommandParsing,
        makeCommandViewModel: @escaping @MainActor () -> HabitCommandViewModel
    ) {
        self.parser = parser
        self.makeCommandViewModel = makeCommandViewModel
    }

    func start() async {
        parser.prepare()

        await transcription.finishTranscribing()
        transcription.startTranscribing()
    }

    func stop() {
        transcription.stopTranscribing()
    }

    func finishAndRecognize() async {
        isFinishing = true
        await transcription.finishTranscribing()
        transcriptForAI = transcription.transcript
        commandViewModel = makeCommandViewModel()
        isFinishing = false
        isPresentingCommand = true
    }

    func dismissCommand() {
        isPresentingCommand = false
    }
}
