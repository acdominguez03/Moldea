//
//  CreateHabitUseCase.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Foundation
import Core

protocol CreateHabitUseCase: Sendable {
    func execute(
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

struct DefaultCreateHabitUseCase: CreateHabitUseCase {
    private let repository: any HabitRepository
    private let notificationScheduler: any HabitNotificationScheduler
    private let makeID: @Sendable () -> UUID
    private let now: @Sendable () -> Date

    init(
        repository: any HabitRepository,
        notificationScheduler: any HabitNotificationScheduler,
        makeID: @escaping @Sendable () -> UUID = { UUID() },
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repository = repository
        self.notificationScheduler = notificationScheduler
        self.makeID = makeID
        self.now = now
    }

    func execute(
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

        let date = now()
        let habit = Habit(
            id: makeID(),
            name: trimmedName,
            color: color,
            icon: icon,
            isActive: true,
            createdAt: date,
            updatedAt: date,
            schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: repetitionsPerDay),
            reminder: HabitReminder(
                time: reminderTime,
                isEnabled: isReminderEnabled,
                isMutedOnWeekends: isMutedOnWeekends
            )
        )
        try await repository.create(habit)
        await notificationScheduler.scheduleReminder(for: habit)
    }
}
