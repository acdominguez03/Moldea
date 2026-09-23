//
//  UpdateHabitReminderUseCase.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Foundation
import Core

protocol UpdateHabitReminderUseCase: Sendable {
    func execute(
        id: Habit.ID,
        isReminderEnabled: Bool,
        reminderTime: Date,
        isMutedOnWeekends: Bool
    ) async throws
}

struct DefaultUpdateHabitReminderUseCase: UpdateHabitReminderUseCase {
    private let repository: any HabitRepository
    private let now: @Sendable () -> Date

    init(
        repository: any HabitRepository,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repository = repository
        self.now = now
    }

    func execute(
        id: Habit.ID,
        isReminderEnabled: Bool,
        reminderTime: Date,
        isMutedOnWeekends: Bool
    ) async throws {
        try await repository.updateReminder(
            id: id,
            reminder: HabitReminder(
                time: reminderTime,
                isEnabled: isReminderEnabled,
                isMutedOnWeekends: isMutedOnWeekends
            ),
            updatedAt: now()
        )
    }
}
