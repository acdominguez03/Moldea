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
        HabitFormContentView(
            habitFormViewModel: dependencies.makeHabitFormViewModel(editing: editing),
            iconCatalog: dependencies.iconCatalog
        )
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
            VStack(alignment: .leading, spacing: 12) {
                HabitSummaryView(
                    color: habitFormViewModel.selectedColor,
                    icon: habitFormViewModel.selectedIcon,
                    name: habitFormViewModel.name,
                    onHabitNameChanged: {
                        habitFormViewModel.onHabitNameChanged($0)
                    }
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(HabitsTextsEnum.iconTitle)
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HabitIconPicker(
                        selectedIcon: habitFormViewModel.selectedIcon,
                        tint: habitFormViewModel.selectedColor,
                        onIconSelected: { habitFormViewModel.selectIcon($0) },
                        onMoreTapped: { isShowingIconChooser = true }
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(HabitsTextsEnum.colorTitle)
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HabitColorPicker(
                        selectedHex: habitFormViewModel.selectedColorHex,
                        onColorSelected: { habitFormViewModel.selectColor(hex: $0) }
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(HabitsTextsEnum.frequency)
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
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
                }
                .animation(
                    .snappy,
                    value: habitFormViewModel.selectedFrequency
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(CoreTextsEnum.announcements)
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    NotificationsPicker(
                        isRemindHabitEnabled: habitFormViewModel
                            .isRemindHabitEnabled,
                        isMutedOnWeekends: habitFormViewModel
                            .isMutedOnWeekends,
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
                }
                
                if let errorMessage = habitFormViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
            .toolbar {
                ToolbarItem(
                    placement: .confirmationAction,
                    content: {
                        Button {
                            Task { await habitFormViewModel.save() }
                        } label: {
                            Text(CoreTextsEnum.save)
                        }
                        .disabled(!habitFormViewModel.canSave)
                    }
                )
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button {
                            dismiss()
                        } label: {
                            Text(CoreTextsEnum.cancel)
                        }
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
}
