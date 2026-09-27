//
//  SetIsDailySummaryEnabledUseCase.swift
//  Settings
//

import Core

protocol SetIsDailySummaryEnabledUseCaseProtocol: Sendable {
    func execute(isEnabled: Bool) async
}

struct SetIsDailySummaryEnabledUseCase: SetIsDailySummaryEnabledUseCaseProtocol {
    private let repository: UserDefaultsRepository
    private let notificationScheduler: any HabitNotificationScheduler

    init(userDefaultsRepository: UserDefaultsRepository, notificationScheduler: any HabitNotificationScheduler) {
        self.repository = userDefaultsRepository
        self.notificationScheduler = notificationScheduler
    }

    /// Guarda la preferencia y sincroniza: el planificador decide si hoy toca el aviso.
    func execute(isEnabled: Bool) async {
        repository.saveBool(PreferenceKeyEnum.isDailySummaryEnabled, isEnabled)
        await notificationScheduler.syncReminders()
    }
}
