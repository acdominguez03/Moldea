//
//  UpdateHabitUseCase.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Foundation
import Core

protocol UpdateHabitUseCase: Sendable {
    func execute(
        id: Habit.ID,
        name: String,
        color: String,
        icon: String,
        frequency: HabitFrequency,
        repetitionsPerDay: Int
    ) async throws
}

struct DefaultUpdateHabitUseCase: UpdateHabitUseCase {
    private let repository: any HabitRepository

    init(repository: any HabitRepository) {
        self.repository = repository
    }

    func execute(
        id: Habit.ID,
        name: String,
        color: String,
        icon: String,
        frequency: HabitFrequency,
        repetitionsPerDay: Int
    ) async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        try HabitValidator.validate(
            trimmedName: trimmedName,
            color: color,
            frequency: frequency,
            repetitionsPerDay: repetitionsPerDay
        )

        try await repository.update(
            id: id,
            name: trimmedName,
            color: color,
            icon: icon,
            schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: repetitionsPerDay),
            updatedAt: .now
        )
    }
}
