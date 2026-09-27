//
//  HabitFormView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI
import Core

struct HabitFormView: View {
    @Environment(\.habitsDependencies) private var dependencies
    var editing: Habit? = nil

    var body: some View {
        if let dependencies {
            HabitFormContentView(
                habitFormViewModel: dependencies.makeHabitFormViewModel(editing: editing),
                iconCatalog: dependencies.iconCatalog
            )
        } else {
            MissingDependenciesView(HabitsDependencies.self)
        }
    }
}

struct HabitFormContentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var habitFormViewModel: HabitFormViewModel
    @State private var isShowingIconChooser = false

    private let iconCatalog: any HabitIconCatalog

    init(habitFormViewModel: HabitFormViewModel, iconCatalog: any HabitIconCatalog) {
        self.habitFormViewModel = habitFormViewModel
        self.iconCatalog = iconCatalog
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HabitSummaryView(
                        color: habitFormViewModel.selectedColor,
                        icon: habitFormViewModel.selectedIcon,
                        name: habitFormViewModel.name,
                        onHabitNameChanged: {
                            habitFormViewModel.onHabitNameChanged($0)
                        }
                    )
                }

                Section {
                    HabitIconPicker(
                        selectedIcon: habitFormViewModel.selectedIcon,
                        tint: habitFormViewModel.selectedColor,
                        onIconSelected: { habitFormViewModel.selectIcon($0) },
                        onMoreTapped: { isShowingIconChooser = true }
                    )
                } header: {
                    Text(HabitsTextsEnum.iconTitle)
                }

                Section {
                    HabitColorPicker(
                        selectedHex: habitFormViewModel.selectedColorHex,
                        onColorSelected: { habitFormViewModel.selectColor(hex: $0) }
                    )
                } header: {
                    Text(HabitsTextsEnum.colorTitle)
                }

                Section {
                    HabitFrequencyPicker(
                        selectedHabitFrequency: habitFormViewModel.selectedFrequency,
                        onFrequencyChanged: {
                            habitFormViewModel.onFrequencyChanged($0)
                        }
                    )

                    TimesADayPicker(
                        range: habitFormViewModel.timesADayRange,
                        selectedTimesADay: habitFormViewModel.selectedTimesADay,
                        onIncrementTimesADay: {
                            habitFormViewModel.onIncrementTimeADayClicked()
                        },
                        onDecrementTimesADay: {
                            habitFormViewModel.onDecrementTimeADayClicked()
                        }
                    )

                    frequencyDetail
                } header: {
                    Text(HabitsTextsEnum.frequency)
                }
                .animation(.snappy, value: habitFormViewModel.selectedFrequency)

                NotificationsPicker(
                    isRemindHabitEnabled: habitFormViewModel.isRemindHabitEnabled,
                    isMutedOnWeekends: habitFormViewModel.isMutedOnWeekends,
                    reminderTime: habitFormViewModel.reminderTime,
                    onRemindHabitToggled: {
                        habitFormViewModel.onRemidHabitToggled($0)
                    },
                    onMuteOnWeekendToggled: {
                        habitFormViewModel.onMuteOnWeekendToggled($0)
                    },
                    onReminderTimeChanged: {
                        habitFormViewModel.onReminderTimeChanged($0)
                    }
                )

                if let errorMessage = habitFormViewModel.errorMessage {
                    Section {
                        Label {
                            Text(errorMessage)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                        }
                        .font(.footnote)
                    }
                }
            }
            .navigationTitle(
                habitFormViewModel.isEditing ? HabitsTextsEnum.editHabit : HabitsTextsEnum.newHabit
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isShowingIconChooser) {
                ChooseHabitIconView(
                    catalog: iconCatalog,
                    selectedIcon: habitFormViewModel.selectedIcon,
                    tint: habitFormViewModel.selectedColor,
                    onIconSelected: { habitFormViewModel.selectIcon($0) }
                )
            }
            .onChange(of: habitFormViewModel.didSave) { _, didSave in
                if didSave { dismiss() }
            }
            .onChange(of: habitFormViewModel.errorMessage) { _, errorMessage in
                guard let errorMessage else { return }
                AccessibilityNotification.Announcement(String(localized: errorMessage)).post()
            }
            .toolbar {
                ToolbarItem(
                    placement: .confirmationAction,
                    content: {
                        Button {
                            Task { await habitFormViewModel.save() }
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .disabled(!habitFormViewModel.canSave)
                        .buttonStyle(.glassProminent)
                        .tint(.accentColor)
                        .accessibilityLabel(HabitsTextsEnum.save)
                    }
                )
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel(CoreTextsEnum.cancel)
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var frequencyDetail: some View {
        switch habitFormViewModel.selectedFrequency {
        case .everyDay:
            EmptyView()
        case .timesPerWeek:
            TimesAWeekPicker(
                range: habitFormViewModel.timesAWeekRange,
                selectedTimesAWeek: habitFormViewModel.selectedTimesAWeek,
                onIncrementTimesAWeek: {
                    habitFormViewModel.onIncrementTimesAWeekClicked()
                },
                onDecrementTimesAWeek: {
                    habitFormViewModel.onDecrementTimesAWeekClicked()
                }
            )
        case .fixedDays:
            WeekDayPicker(
                weekdays: habitFormViewModel.weekdayItems,
                selectedWeekdays: habitFormViewModel.selectedWeekdays,
                onWeekDayItemToggled: {
                    habitFormViewModel.onWeekdayToggled($0)
                }
            )
        }
    }
}

#Preview {
    HabitFormView()
        .environment(\.habitsDependencies, .preview)
}
