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
        repetitionsPerDay: Int,
        isReminderEnabled: Bool,
        reminderTime: Date,
        isMutedOnWeekends: Bool
    ) async throws
}

struct DefaultUpdateHabitUseCase: UpdateHabitUseCase {
    private let repository: any HabitRepository
    private let notificationScheduler: any HabitNotificationScheduler

    init(repository: any HabitRepository, notificationScheduler: any HabitNotificationScheduler) {
        self.repository = repository
        self.notificationScheduler = notificationScheduler
    }

    func execute(
        id: Habit.ID,
        name: String,
        color: String,
        icon: String,
        frequency: HabitFrequency,
        repetitionsPerDay: Int,
        isReminderEnabled: Bool,
        reminderTime: Date,
        isMutedOnWeekends: Bool
    ) async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        try HabitValidator.validate(
            trimmedName: trimmedName,
            color: color,
            frequency: frequency,
            repetitionsPerDay: repetitionsPerDay
        )

        let schedule = HabitSchedule(frequency: frequency, repetitionsPerDay: repetitionsPerDay)
        let reminder = HabitReminder(
            time: reminderTime,
            isEnabled: isReminderEnabled,
            isMutedOnWeekends: isMutedOnWeekends
        )
        let date = Date.now

        try await repository.update(
            id: id,
            name: trimmedName,
            color: color,
            icon: icon,
            schedule: schedule,
            reminder: reminder,
            updatedAt: date
        )

        await notificationScheduler.cancelReminders(for: id)
        await notificationScheduler.scheduleReminder(for: Habit(
            id: id,
            name: trimmedName,
            color: color,
            icon: icon,
            isActive: true,
            createdAt: date,
            updatedAt: date,
            schedule: schedule,
            reminder: reminder
        ))
    }
}
