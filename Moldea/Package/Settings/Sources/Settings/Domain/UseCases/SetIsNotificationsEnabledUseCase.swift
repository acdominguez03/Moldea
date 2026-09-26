//
//  SetIsNotificationsEnabledUseCase.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Core

protocol SetIsNotificationsEnabledUseCaseProtocol: Sendable {
    func execute(isEnabled: Bool, habits: [Habit]) async throws
}

struct SetIsNotificationsEnabledUseCase: SetIsNotificationsEnabledUseCaseProtocol {
    private let repository: UserDefaultsRepository
    private let notificationScheduler: any HabitNotificationScheduler

    init(userDefaultsRepository: UserDefaultsRepository, notificationScheduler: any HabitNotificationScheduler) {
        self.repository = userDefaultsRepository
        self.notificationScheduler = notificationScheduler
    }

    func execute(isEnabled: Bool, habits: [Habit]) async throws {
        repository.saveBool(PreferenceKey.isNotificationsEnabled, isEnabled)

        // Limpieza total en los dos sentidos: no depende de que la base de datos sepa qué hay
        // programado, así que también quita restos de hábitos pausados, borrados o con el aviso
        // ya apagado.
        await notificationScheduler.cancelAllReminders()

        guard isEnabled else { return }

        for habit in habits where habit.isActive && habit.hasActiveReminder {
            await notificationScheduler.scheduleReminder(for: habit)
        }
    }
}
