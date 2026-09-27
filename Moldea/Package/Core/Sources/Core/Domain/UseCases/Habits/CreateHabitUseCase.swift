//
//  CreateHabitUseCase.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Foundation

public protocol CreateHabitUseCase: Sendable {
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

public extension CreateHabitUseCase {
    /// Crea el hábito sin recordatorio. Es lo que usan los flujos que no lo configuran (p. ej. la IA).
    func execute(
        name: String,
        color: String,
        icon: String,
        frequency: HabitFrequency,
        repetitionsPerDay: Int
    ) async throws {
        try await execute(
            name: name,
            color: color,
            icon: icon,
            frequency: frequency,
            repetitionsPerDay: repetitionsPerDay,
            isReminderEnabled: false,
            reminderTime: .now,
            isMutedOnWeekends: false
        )
    }
}

public struct DefaultCreateHabitUseCase: CreateHabitUseCase {
    private let repository: any HabitRepository
    private let notificationScheduler: any HabitNotificationScheduler
    private let makeID: @Sendable () -> UUID
    private let now: @Sendable () -> Date

    public init(
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

    public func execute(
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
