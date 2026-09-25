//
//  SettingsDependencies.swift
//  Settings
//
//  Created by Andrés on 25/09/2026.
//

import Core
import SwiftUI

public struct SettingsDependencies: Sendable {
    let core: CoreDependencies

    public init(core: CoreDependencies) {
        self.core = core
    }

    public static let preview = SettingsDependencies(core: .preview)

    @MainActor func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            setHabitReminderEnabledUseCase: DefaultSetHabitReminderEnabledUseCase(
                repository: core.habitRepository
            ),
            getIsNotificationsEnabledUseCase: GetIsNotificationsEnabledUseCase(
                userDefaultsRepository: core.userDefaultsRepository
            ),
            setIsNotificationsEnabledUseCase: SetIsNotificationsEnabledUseCase(
                userDefaultsRepository: core.userDefaultsRepository,
                notificationScheduler: core.notificationScheduler
            ),
            getIsNotificationPermissionAllowedUseCase: GetIsNotificationPermissionAllowedUseCase(
                userDefaultsRepository: core.userDefaultsRepository
            ),
            requestNotificationAuthorizationUseCase: core.requestNotificationAuthorization
        )
    }

    @MainActor func makeHabitReminderSheetViewModel(habit: Habit) -> HabitReminderSheetViewModel {
        HabitReminderSheetViewModel(
            habit: habit,
            updateHabitReminderUseCase: DefaultUpdateHabitReminderUseCase(
                repository: core.habitRepository,
                notificationScheduler: core.notificationScheduler
            )
        )
    }
}

extension EnvironmentValues {
    @Entry public var settingsDependencies = SettingsDependencies.preview
}
