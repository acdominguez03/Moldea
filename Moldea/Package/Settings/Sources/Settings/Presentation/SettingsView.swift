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
    @State private var settingsViewModel: SettingsViewModel
    @State private var habitToEditReminder: Habit?
    @HabitsQuery private var habits: [Habit]
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    private let habitRepository: any HabitRepository
    private let userDefaultsRepository: UserDefaultsRepository
    
    private var isNotificationsEnabledBinding: Binding<Bool> {
        Binding(
            get: { settingsViewModel.isNotificationsEnabled },
            set: { _ in Task { await settingsViewModel.onIsNotificationsEnabledToggled(habits: habits) } }
        )
    }
    
    public init(habitRepository: any HabitRepository, userDefaultsRepository: any UserDefaultsRepository) {
        self.habitRepository = habitRepository
        self.userDefaultsRepository = userDefaultsRepository
        
        _settingsViewModel = State(
            initialValue: SettingsViewModel(
                setHabitReminderEnabledUseCase: DefaultSetHabitReminderEnabledUseCase(
                    repository: habitRepository
                ),
                getIsNotificationsEnabledUseCase: GetIsNotificationsEnabledUseCase(
                    userDefaultsRepository: userDefaultsRepository
                ),
                setIsNotificationsEnabledUseCase: SetIsNotificationsEnabledUseCase(
                    userDefaultsRepository: userDefaultsRepository,
                    notificationScheduler: UNUserNotificationCenterHabitNotificationScheduler(
                        userDefaultsRepository: userDefaultsRepository
                    )
                ),
                getIsNotificationPermissionAllowedUseCase: GetIsNotificationPermissionAllowedUseCase(
                    userDefaultsRepository: userDefaultsRepository
                ),
                requestNotificationAuthorizationUseCase: DefaultRequestNotificationAuthorizationUseCase(
                    notificationPermissionRepository: UNUserNotificationCenterPermissionRepository(),
                    userDefaultsRepository: userDefaultsRepository
                ),
            )
        )
    }

    private func openNotificationSettings() {
        let urlString = UIApplication.openNotificationSettingsURLString
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }
    
    private var activeHabits: [Habit] {
        habits.filter(\.isActive)
    }
    
    private var activeRemindersCount: Int {
        activeHabits.count(where: \.hasActiveReminder)
    }
    
    
    public var body: some View {
        NavigationStack {
            List {
                if settingsViewModel.isNotificationPermissionAllowed {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(
                                isOn: isNotificationsEnabledBinding,
                                label : {
                                    Text(SettingsTextsEnum.allowAnnouncements)
                                        .bold()

                                    Text(
                                        settingsViewModel.isNotificationsEnabled || activeRemindersCount == 0 ?
                                            SettingsTextsEnum
                                                .habitThatAnnounce(
                                                    activeHabits.count,
                                                    activeRemindersCount,
                                                )
                                        : SettingsTextsEnum.everythingMuted
                                    )
                                },
                            )
                        }
                    } header: {
                        Text(SettingsTextsEnum.notifications)
                            .textCase(.uppercase)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if !habits.isEmpty && settingsViewModel.isNotificationsEnabled {
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
                        } header : {
                            Text(SettingsTextsEnum.chooseHabitsAnnouncements)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Section {
                        NotificationPermissionDisabledRow(onRowTapped: openNotificationSettings)
                    } header: {
                        Text(SettingsTextsEnum.notifications)
                            .textCase(.uppercase)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle(SettingsTextsEnum.screenTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $habitToEditReminder) { habit in
                HabitReminderSheet(
                    habit: habit,
                    habitReminderSheetViewModel: HabitReminderSheetViewModel(
                        habit: habit,
                        updateHabitReminderUseCase: DefaultUpdateHabitReminderUseCase(
                            repository: habitRepository,
                            notificationScheduler: UNUserNotificationCenterHabitNotificationScheduler(
                                userDefaultsRepository: userDefaultsRepository
                            )
                        )
                    )
                )
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await settingsViewModel.refreshNotificationPermissionStatus() }
                }
            }
        }
    }
}

#Preview {
    SettingsView(
        habitRepository: SwiftDataHabitRepository(
            modelContainer: try! MoldeaSchema.makeModelContainer(inMemory: true)
        ),
        userDefaultsRepository: UserDefaultsRepositoryImpl()
    )
}
