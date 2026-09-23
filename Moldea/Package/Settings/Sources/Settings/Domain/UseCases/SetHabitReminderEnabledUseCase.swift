//
//  SetHabitReminderEnabledUseCase.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Foundation
import Core

protocol SetHabitReminderEnabledUseCase: Sendable {
    func execute(id: Habit.ID, isEnabled: Bool) async throws
}

struct DefaultSetHabitReminderEnabledUseCase: SetHabitReminderEnabledUseCase {
    private let repository: any HabitRepository
    private let now: @Sendable () -> Date
    private let defaultReminderTime: @Sendable () -> Date

    init(
        repository: any HabitRepository,
        now: @escaping @Sendable () -> Date = { .now },
        defaultReminderTime: @escaping @Sendable () -> Date = Self.makeDefaultReminderTime
    ) {
        self.repository = repository
        self.now = now
        self.defaultReminderTime = defaultReminderTime
    }

    func execute(id: Habit.ID, isEnabled: Bool) async throws {
        try await repository.setReminderEnabled(
            id: id,
            isEnabled: isEnabled,
            defaultTime: defaultReminderTime(),
            updatedAt: now()
        )
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
