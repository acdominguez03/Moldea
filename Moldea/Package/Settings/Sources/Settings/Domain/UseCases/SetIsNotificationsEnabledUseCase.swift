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

        let habitsWithReminder = habits.filter { $0.isActive && $0.hasActiveReminder }
        if isEnabled {
            for habit in habitsWithReminder {
                await notificationScheduler.scheduleReminder(for: habit)
            }
        } else {
            for habit in habitsWithReminder {
                await notificationScheduler.cancelReminders(for: habit.id)
            }
        }
    }
}
