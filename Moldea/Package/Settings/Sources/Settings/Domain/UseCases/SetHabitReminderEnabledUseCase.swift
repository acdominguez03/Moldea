//
//  SetHabitReminderEnabledUseCase.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Foundation
import Core

protocol SetHabitReminderEnabledUseCase: Sendable {
    func execute(habit: Habit, isEnabled: Bool) async throws
}

struct DefaultSetHabitReminderEnabledUseCase: SetHabitReminderEnabledUseCase {
    private let repository: any HabitRepository
    private let notificationScheduler: any HabitNotificationScheduler
    private let now: @Sendable () -> Date
    private let defaultReminderTime: @Sendable () -> Date

    init(
        repository: any HabitRepository,
        notificationScheduler: any HabitNotificationScheduler,
        now: @escaping @Sendable () -> Date = { .now },
        defaultReminderTime: @escaping @Sendable () -> Date = Self.makeDefaultReminderTime
    ) {
        self.repository = repository
        self.notificationScheduler = notificationScheduler
        self.now = now
        self.defaultReminderTime = defaultReminderTime
    }

    func execute(habit: Habit, isEnabled: Bool) async throws {
        let defaultTime = defaultReminderTime()
        let date = now()

        try await repository.setReminderEnabled(
            id: habit.id,
            isEnabled: isEnabled,
            defaultTime: defaultTime,
            updatedAt: date
        )

        // Antes solo se guardaba el ajuste: apagar el aviso de un hábito dejaba sus notificaciones
        // programadas, y encenderlo no programaba ninguna.
        await notificationScheduler.cancelReminders(for: habit.id)

        guard isEnabled else { return }

        await notificationScheduler.scheduleReminder(for: Habit(
            id: habit.id,
            name: habit.name,
            color: habit.color,
            icon: habit.icon,
            isActive: habit.isActive,
            createdAt: habit.createdAt,
            updatedAt: date,
            schedule: habit.schedule,
            reminder: HabitReminder(
                time: habit.reminder?.time ?? defaultTime,
                isEnabled: true,
                isMutedOnWeekends: habit.reminder?.isMutedOnWeekends ?? false
            ),
            inactivePeriods: habit.inactivePeriods
        ))
    }

    /// Hora que se asigna cuando se activa el recordatorio de un hábito que nunca tuvo uno
    /// configurado. Mismo valor por defecto que `HabitFormViewModel` en `Habits`.
    private static func makeDefaultReminderTime() -> Date {
        Calendar.current.date(
            bySettingHour: 8,
            minute: 0,
            second: 0,
            of: .now
        ) ?? .now
    }
}
