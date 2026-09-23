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

    private let setHabitReminderEnabledUseCase: any SetHabitReminderEnabledUseCase
    private let getIsNotificationsEnabledUseCase: GetIsNotificationsEnabledUseCase
    private let setIsNotificationsEnabledUseCase: SetIsNotificationsEnabledUseCase

    init(
        setHabitReminderEnabledUseCase: any SetHabitReminderEnabledUseCase,
        getIsNotificationsEnabledUseCase: GetIsNotificationsEnabledUseCase,
        setIsNotificationsEnabledUseCase: SetIsNotificationsEnabledUseCase
    ) {
        self.setHabitReminderEnabledUseCase = setHabitReminderEnabledUseCase
        self.getIsNotificationsEnabledUseCase = getIsNotificationsEnabledUseCase
        self.setIsNotificationsEnabledUseCase = setIsNotificationsEnabledUseCase
        
        isNotificationsEnabled = getIsNotificationsEnabledUseCase.execute()
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
            try await setHabitReminderEnabledUseCase.execute(id: habit.id, isEnabled: isEnabled)
        }
    }
    
    func onIsNotificationsEnabledToggled() {
        do {
            try setIsNotificationsEnabledUseCase
                .execute(isEnabled: !isNotificationsEnabled)
            
            isNotificationsEnabled.toggle()
        } catch {
            print("ERRRRROR")
        }
    }
}
