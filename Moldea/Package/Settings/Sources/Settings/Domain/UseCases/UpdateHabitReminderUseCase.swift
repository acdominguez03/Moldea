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
        habit: Habit,
        isReminderEnabled: Bool,
        reminderTime: Date,
        isMutedOnWeekends: Bool
    ) async throws
}

struct DefaultUpdateHabitReminderUseCase: UpdateHabitReminderUseCase {
    private let repository: any HabitRepository
    private let notificationScheduler: any HabitNotificationScheduler
    private let now: @Sendable () -> Date

    init(
        repository: any HabitRepository,
        notificationScheduler: any HabitNotificationScheduler,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repository = repository
        self.notificationScheduler = notificationScheduler
        self.now = now
    }

    func execute(
        habit: Habit,
        isReminderEnabled: Bool,
        reminderTime: Date,
        isMutedOnWeekends: Bool
    ) async throws {
        let reminder = HabitReminder(
            time: reminderTime,
            isEnabled: isReminderEnabled,
            isMutedOnWeekends: isMutedOnWeekends
        )
        let date = now()

        try await repository.updateReminder(id: habit.id, reminder: reminder, updatedAt: date)

        await notificationScheduler.cancelReminders(for: habit.id)
        await notificationScheduler.scheduleReminder(for: Habit(
            id: habit.id,
            name: habit.name,
            color: habit.color,
            icon: habit.icon,
            isActive: habit.isActive,
            createdAt: habit.createdAt,
            updatedAt: date,
            schedule: habit.schedule,
            reminder: reminder
        ))
    }
}
