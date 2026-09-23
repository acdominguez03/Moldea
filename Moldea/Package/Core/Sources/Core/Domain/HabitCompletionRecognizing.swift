//
//  HabitCompletionRecognizing.swift
//  Core
//
//  Created by Andrés on 21/09/2026.
//

@MainActor
protocol HabitCompletionRecognizing {
    var availability: LanguageModelAvailabilityEnum { get }

    func prepare()

    func recognizeCompletions(in transcript: String, from knownHabits: [Habit]) async throws -> [Habit]
}
