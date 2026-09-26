//
//  SettingsView.swift
//  Settings
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import UIKit
import Core

public struct SettingsView: View {
    @Environment(\.settingsDependencies) private var dependencies

    public init() {}

    public var body: some View {
        SettingsContentView(viewModel: dependencies.makeSettingsViewModel())
    }
}

struct SettingsContentView: View {
    @State private var settingsViewModel: SettingsViewModel
    @State private var habitToEditReminder: Habit?
    @HabitsQuery private var habits: [Habit]
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Environment(\.settingsDependencies) private var dependencies

    private var isNotificationsEnabledBinding: Binding<Bool> {
        Binding(
            get: { settingsViewModel.isNotificationsEnabled },
            set: { _ in Task { await settingsViewModel.onIsNotificationsEnabledToggled(habits: habits) } }
        )
    }
    
    init(viewModel: SettingsViewModel) {
        _settingsViewModel = State(initialValue: viewModel)
    }

    private func openNotificationSettings() {
        let urlString = UIApplication.openNotificationSettingsURLString
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }
    
    private var activeHabits: [Habit] {
        habits.filter(\.isActive)
    }
    
    private var showsHabitReminders: Bool {
        !habits.isEmpty && settingsViewModel.isNotificationsEnabled
    }

    private var activeRemindersCount: Int {
        activeHabits.count(where: \.hasActiveReminder)
    }
    

    var body: some View {
        NavigationStack {
            List {
                if settingsViewModel.isNotificationPermissionAllowed {
                    Section {
                        Toggle(
                            isOn: isNotificationsEnabledBinding,
                            label: {
                                Text(SettingsTextsEnum.allowAnnouncements)

                                Text(
                                    settingsViewModel.isNotificationsEnabled || activeRemindersCount == 0 ?
                                        SettingsTextsEnum
                                            .habitThatAnnounce(
                                                activeHabits.count,
                                                activeRemindersCount,
                                            )
                                    : SettingsTextsEnum.everythingMuted
                                )
                            }
                        )
                    } header: {
                        Text(SettingsTextsEnum.notifications)
                    } footer: {
                        if showsHabitReminders {
                            Text(SettingsTextsEnum.chooseHabitsAnnouncements)
                        }
                    }
                    if showsHabitReminders {
                        Section {
                            ForEach(activeHabits) { habit in
                                HabitReminderRow(
                                    habit: habit,
                                    onReminderToggled: {
                                        Task { await settingsViewModel.onHabitReminderToggled(habit) }
                                    },
                                    onRowTapped: {
                                        habitToEditReminder = habit
                                    }
                                )
                            }
                        }
                    }
                } else {
                    Section {
                        NotificationPermissionDisabledRow(onRowTapped: openNotificationSettings)
                    } header: {
                        Text(SettingsTextsEnum.notifications)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(SettingsTextsEnum.screenTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $habitToEditReminder) { habit in
                HabitReminderSheet(
                    habit: habit,
                    habitReminderSheetViewModel: dependencies.makeHabitReminderSheetViewModel(habit: habit)
                )
                .presentationDetents([.medium, .large])
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await settingsViewModel.refreshNotificationPermissionStatus()
                    }
                }
            }
        }
    }
}

#Preview(traits: .moldea) {
    SettingsView()
}
