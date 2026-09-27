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
        if let dependencies {
            SettingsContentView(
                viewModel: dependencies.makeSettingsViewModel(),
                makeReminderSheetViewModel: dependencies.makeHabitReminderSheetViewModel(habit:)
            )
        } else {
            MissingDependenciesView(SettingsDependencies.self)
        }
    }
}

struct SettingsContentView: View {
    @State private var settingsViewModel: SettingsViewModel
    @State private var habitToEditReminder: Habit?
    @HabitsQuery private var habits: [Habit]
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    private let makeReminderSheetViewModel: @MainActor (Habit) -> HabitReminderSheetViewModel

    private var isNotificationsEnabledBinding: Binding<Bool> {
        Binding(
            get: { settingsViewModel.isNotificationsEnabled },
            set: { _ in Task { await settingsViewModel.onIsNotificationsEnabledToggled() } }
        )
    }
    
    private var isDailySummaryEnabledBinding: Binding<Bool> {
        Binding(
            get: { settingsViewModel.isDailySummaryEnabled },
            set: { _ in Task { await settingsViewModel.onIsDailySummaryToggled() } }
        )
    }

    init(
        viewModel: SettingsViewModel,
        makeReminderSheetViewModel: @escaping @MainActor (Habit) -> HabitReminderSheetViewModel
    ) {
        _settingsViewModel = State(initialValue: viewModel)
        self.makeReminderSheetViewModel = makeReminderSheetViewModel
    }

    private func openNotificationSettings() {
        let urlString = UIApplication.openNotificationSettingsURLString
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
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

                        Section {
                            Toggle(
                                SettingsTextsEnum.dailySummaryToggle,
                                isOn: isDailySummaryEnabledBinding
                            )
                        } header: {
                            Text(SettingsTextsEnum.daySummary)
                        } footer: {
                            Text(SettingsTextsEnum.oneReminderWithHabitsLeft)
                        }
                    }
                } else {
                    Section {
                        PermissionDisabledRow(
                            icon: "bell.slash.fill",
                            title: SettingsTextsEnum.notificationsPermissionDisabledTitle,
                            description: SettingsTextsEnum.notificationsPermissionDisabledDescription,
                            onRowTapped: openNotificationSettings
                        )
                    } header: {
                        Text(SettingsTextsEnum.notifications)
                    }
                }

                if settingsViewModel.showsMicrophonePermissionRow {
                    Section {
                        PermissionDisabledRow(
                            icon: "mic.slash.fill",
                            title: SettingsTextsEnum.microphonePermissionDisabledTitle,
                            description: SettingsTextsEnum.microphonePermissionDisabledDescription,
                            onRowTapped: openAppSettings
                        )
                    } header: {
                        Text(SettingsTextsEnum.voiceCommands)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(SettingsTextsEnum.screenTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $habitToEditReminder) { habit in
                HabitReminderSheet(
                    habit: habit,
                    habitReminderSheetViewModel: makeReminderSheetViewModel(habit)
                )
                .presentationDetents([.medium, .large])
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    settingsViewModel.refreshMicrophonePermissionStatus()
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
        .environment(\.settingsDependencies, .preview)
}
