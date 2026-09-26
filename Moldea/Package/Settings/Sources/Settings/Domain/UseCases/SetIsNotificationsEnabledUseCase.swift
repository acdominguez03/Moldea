//
//  SetIsNotificationsEnabledUseCase.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Core

protocol SetIsNotificationsEnabledUseCaseProtocol: Sendable {
    func execute(isEnabled: Bool) async throws
}

struct SetIsNotificationsEnabledUseCase: SetIsNotificationsEnabledUseCaseProtocol {
    private let repository: UserDefaultsRepository
    private let notificationScheduler: any HabitNotificationScheduler

    init(userDefaultsRepository: UserDefaultsRepository, notificationScheduler: any HabitNotificationScheduler) {
        self.repository = userDefaultsRepository
        self.notificationScheduler = notificationScheduler
    }

    func execute(isEnabled: Bool) async throws {
        repository.saveBool(PreferenceKey.isNotificationsEnabled, isEnabled)
        await notificationScheduler.cancelAllReminders()
        guard isEnabled else { return }
        await notificationScheduler.syncReminders()
    }
}
