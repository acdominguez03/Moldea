//
//  SettingsViewModel.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Observation
import SwiftUI
import Core

@Observable
@MainActor
final class SettingsViewModel: BaseViewModel {
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: LocalizedStringResource?
    
    private(set) var isNotificationsEnabled: Bool
    private(set) var isNotificationPermissionAllowed: Bool
    private(set) var isDailySummaryEnabled: Bool

    private let setHabitReminderEnabledUseCase: any SetHabitReminderEnabledUseCase
    private let getIsNotificationsEnabledUseCase: GetIsNotificationsEnabledUseCase
    private let setIsNotificationsEnabledUseCase: SetIsNotificationsEnabledUseCase
    private let getIsNotificationPermissionAllowedUseCase: GetIsNotificationPermissionAllowedUseCase
    private let setIsDailySummaryEnabledUseCase: SetIsDailySummaryEnabledUseCase
    private let requestNotificationAuthorizationUseCase: any RequestNotificationAuthorizationUseCase

    init(
        setHabitReminderEnabledUseCase: any SetHabitReminderEnabledUseCase,
        getIsNotificationsEnabledUseCase: GetIsNotificationsEnabledUseCase,
        setIsNotificationsEnabledUseCase: SetIsNotificationsEnabledUseCase,
        getIsNotificationPermissionAllowedUseCase: GetIsNotificationPermissionAllowedUseCase,
        getIsDailySummaryEnabledUseCase: GetIsDailySummaryEnabledUseCase,
        setIsDailySummaryEnabledUseCase: SetIsDailySummaryEnabledUseCase,
        requestNotificationAuthorizationUseCase: any RequestNotificationAuthorizationUseCase
    ) {
        self.setHabitReminderEnabledUseCase = setHabitReminderEnabledUseCase
        self.getIsNotificationsEnabledUseCase = getIsNotificationsEnabledUseCase
        self.setIsNotificationsEnabledUseCase = setIsNotificationsEnabledUseCase
        self.getIsNotificationPermissionAllowedUseCase = getIsNotificationPermissionAllowedUseCase
        self.setIsDailySummaryEnabledUseCase = setIsDailySummaryEnabledUseCase
        self.requestNotificationAuthorizationUseCase = requestNotificationAuthorizationUseCase

        isNotificationsEnabled = getIsNotificationsEnabledUseCase.execute()
        isNotificationPermissionAllowed = getIsNotificationPermissionAllowedUseCase.execute()
        isDailySummaryEnabled = getIsDailySummaryEnabledUseCase.execute()
    }

    func refreshNotificationPermissionStatus() async {
        isNotificationPermissionAllowed = await requestNotificationAuthorizationUseCase.execute()
    }

    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func setError(_ message: LocalizedStringResource?) {
        errorMessage = message
    }

    func onHabitReminderToggled(_ habit: Habit) async {
        let isEnabled = !(habit.reminder?.isEnabled ?? false)
        await perform {
            try await setHabitReminderEnabledUseCase.execute(habit: habit, isEnabled: isEnabled)
        }
    }
    
    func onIsNotificationsEnabledToggled() async {
        let isEnabled = !isNotificationsEnabled
        await perform {
            try await setIsNotificationsEnabledUseCase.execute(isEnabled: isEnabled)
            isNotificationsEnabled = isEnabled
        }
    }

    func onIsDailySummaryToggled() async {
        let isEnabled = !isDailySummaryEnabled
        // El interruptor cambia al instante y la sincronización va después: esperarla (hasta un
        // segundo) retrasaba el valor que ve y anuncia VoiceOver, y dos toques seguidos leían un
        // estado antiguo. El caso de uso no falla, así que no hay nada que deshacer.
        isDailySummaryEnabled = isEnabled
        await setIsDailySummaryEnabledUseCase.execute(isEnabled: isEnabled)
    }
}
