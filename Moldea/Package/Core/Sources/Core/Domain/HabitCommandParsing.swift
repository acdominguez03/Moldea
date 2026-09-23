//
//  HabitCommandParsing.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

@MainActor
protocol HabitCommandParsing {
    var availability: LanguageModelAvailabilityEnum { get }

    func prepare()

    func parseCommand(in transcript: String, from knownHabits: [Habit]) async throws -> HabitCommandEnum
}
