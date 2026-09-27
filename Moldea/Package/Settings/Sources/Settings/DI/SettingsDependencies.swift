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
                repository: core.habitRepository,
                notificationScheduler: core.notificationScheduler
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
            getIsDailySummaryEnabledUseCase: GetIsDailySummaryEnabledUseCase(
                userDefaultsRepository: core.userDefaultsRepository
            ),
            setIsDailySummaryEnabledUseCase: SetIsDailySummaryEnabledUseCase(
                userDefaultsRepository: core.userDefaultsRepository,
                notificationScheduler: core.notificationScheduler
            ),
            requestNotificationAuthorizationUseCase: core.requestNotificationAuthorization,
            getMicrophonePermissionStatusUseCase: GetMicrophonePermissionStatusUseCase(
                microphonePermissionRepository: core.microphonePermissionRepository
            ),
            isVoiceInputAvailable: FoundationModelsDeviceEligibility.isDeviceEligible
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
