//
//  HabitReminderSheetViewModel.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Observation
import SwiftUI
import Core

@Observable
@MainActor
final class HabitReminderSheetViewModel: BaseViewModel {
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: LocalizedStringResource?
    private(set) var didSave = false

    private(set) var isReminderEnabled: Bool
    private(set) var isMutedOnWeekends: Bool
    private(set) var reminderTime: Date

    private let habit: Habit
    private let updateHabitReminderUseCase: any UpdateHabitReminderUseCase

    init(habit: Habit, updateHabitReminderUseCase: any UpdateHabitReminderUseCase) {
        self.habit = habit
        self.updateHabitReminderUseCase = updateHabitReminderUseCase
        self.isReminderEnabled = habit.reminder?.isEnabled ?? false
        self.isMutedOnWeekends = habit.reminder?.isMutedOnWeekends ?? false
        self.reminderTime = habit.reminder?.time ?? Self.defaultReminderTime()
    }

    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func setError(_ message: LocalizedStringResource?) {
        errorMessage = message
    }

    func onRemindHabitToggled(_ isEnabled: Bool) {
        isReminderEnabled = isEnabled
    }

    func onMuteOnWeekendToggled(_ isEnabled: Bool) {
        isMutedOnWeekends = isEnabled
    }

    func onReminderTimeChanged(_ newReminderTime: Date) {
        reminderTime = newReminderTime
    }

    func save() async {
        await perform {
            try await updateHabitReminderUseCase.execute(
                habit: habit,
                isReminderEnabled: isReminderEnabled,
                reminderTime: reminderTime,
                isMutedOnWeekends: isMutedOnWeekends
            )
            didSave = true
        }
    }

    private static func defaultReminderTime() -> Date {
        Calendar.current.date(
            bySettingHour: 8,
            minute: 0,
            second: 0,
            of: .now
        ) ?? .now
    }
}
