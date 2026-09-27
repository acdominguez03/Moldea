//
//  UpdateHabitUseCase.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Foundation

public protocol UpdateHabitUseCase: Sendable {
    func execute(
        id: Habit.ID,
        isActive: Bool,
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

public struct DefaultUpdateHabitUseCase: UpdateHabitUseCase {
    private let repository: any HabitRepository
    private let notificationScheduler: any HabitNotificationScheduler

    public init(repository: any HabitRepository, notificationScheduler: any HabitNotificationScheduler) {
        self.repository = repository
        self.notificationScheduler = notificationScheduler
    }

    public func execute(
        id: Habit.ID,
        isActive: Bool,
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
            isActive: isActive,
            createdAt: date,
            updatedAt: date,
            schedule: schedule,
            reminder: reminder
        ))
    }
}
