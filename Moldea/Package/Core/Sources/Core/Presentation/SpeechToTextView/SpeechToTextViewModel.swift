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

    let parser: any HabitCommandParsing
    let createHabitUseCase: any CreateHabitUseCase
    let deleteHabitUseCase: any DeleteHabitUseCase
    let completeHabitsUseCase: any CompleteHabitsUseCase
    let getTodayHabitsUseCase: any GetTodayHabitsUseCase

    private let transcription = LiveTranscriptionModel()

    var phase: TranscriptionPhaseEnum { transcription.phase }
    var downloadProgress: Progress? { transcription.downloadProgress }
    var styledTranscript: AttributedString { transcription.styledTranscript }
    var hasTranscript: Bool { transcription.hasTranscript }
    var isTranscribing: Bool { transcription.isTranscribing }
    var canFinish: Bool { !isFinishing }
    var canClose: Bool { !transcription.isPreparing && !isFinishing }

    init(
        habitRepository: any HabitRepository,
        todayHabitsRepository: any TodayHabitsRepository,
        notificationScheduler: any HabitNotificationScheduler,
        parser: any HabitCommandParsing = FoundationModelsHabitCommandParser()
    ) {
        self.parser = parser
        createHabitUseCase = DefaultCreateHabitUseCase(
            repository: habitRepository,
            notificationScheduler: notificationScheduler
        )
        deleteHabitUseCase = DefaultDeleteHabitUseCase(
            repository: habitRepository,
            notificationScheduler: notificationScheduler
        )
        completeHabitsUseCase = DefaultCompleteHabitsUseCase(
            repository: habitRepository,
            notificationScheduler: notificationScheduler
        )
        getTodayHabitsUseCase = DefaultGetTodayHabitsUseCase(repository: todayHabitsRepository)
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
        isFinishing = false
        isPresentingCommand = true
    }

    func dismissCommand() {
        isPresentingCommand = false
    }
}
