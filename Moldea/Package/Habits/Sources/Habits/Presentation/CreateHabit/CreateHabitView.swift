//
//  CreateHabitView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI
import Core

struct CreateHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var createHabitViewModel: CreateHabitViewModel
    @State private var isShowingIconChooser = false

    private let iconCatalog: any HabitIconCatalog

    init(createHabitViewModel: CreateHabitViewModel, iconCatalog: any HabitIconCatalog) {
        self.createHabitViewModel = createHabitViewModel
        self.iconCatalog = iconCatalog
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HabitSummaryView(
                    color: createHabitViewModel.selectedColor,
                    icon: createHabitViewModel.selectedIcon,
                    name: createHabitViewModel.name,
                    onHabitNameChanged: {
                        createHabitViewModel.onHabitNameChanged($0)
                    }
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(HabitsTextsEnum.iconTitle)
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HabitIconPicker(
                        selectedIcon: createHabitViewModel.selectedIcon,
                        tint: createHabitViewModel.selectedColor,
                        onIconSelected: { createHabitViewModel.selectIcon($0) },
                        onMoreTapped: { isShowingIconChooser = true }
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(HabitsTextsEnum.colorTitle)
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HabitColorPicker(
                        selectedColor: createHabitViewModel.selectedColor,
                        onColorSelected: { createHabitViewModel.selectColor($0) }
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(HabitsTextsEnum.frequency)
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    HabitFrequencyPicker(
                        selectedHabitFrequency: createHabitViewModel.selectedFrequency,
                        onFrequencyChanged: {
                            createHabitViewModel.onFrequencyChanged($0)
                        }
                    )
                    
                    TimesADayPicker(
                        range: createHabitViewModel.timesADayRange,
                        selectedTimesADay: createHabitViewModel.selectedTimesADay,
                        onIncrementTimesADay: {
                            createHabitViewModel.onIncrementTimeADayClicked()
                        },
                        onDecrementTimesADay: {
                            createHabitViewModel.onDecrementTimeADayClicked()
                        }
                    )
                    
                    frequencyDetail
                }
                .animation(
                    .snappy,
                    value: createHabitViewModel.selectedFrequency
                )
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle(HabitsTextsEnum.newHabit)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isShowingIconChooser) {
                ChooseHabitIconView(
                    catalog: iconCatalog,
                    selectedIcon: createHabitViewModel.selectedIcon,
                    tint: createHabitViewModel.selectedColor,
                    onIconSelected: { createHabitViewModel.selectIcon($0) }
                )
            }
            .toolbar {
                ToolbarItem(
                    placement: .confirmationAction,
                    content: {
                        Button {
                            dismiss()
                        } label: {
                            Text(CoreTextsEnum.save)
                        }
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
        switch createHabitViewModel.selectedFrequency {
        case .everyDay:
            EmptyView()
        case .timesPerWeek:
            TimesAWeekPicker(
                range: createHabitViewModel.timesAWeekRange,
                selectedTimesAWeek: createHabitViewModel.selectedTimesAWeek,
                onIncrementTimesAWeek: {
                    createHabitViewModel.onIncrementTimesAWeekClicked()
                },
                onDecrementTimesAWeek: {
                    createHabitViewModel.onDecrementTimesAWeekClicked()
                }
            )
        case .fixedDays:
            WeekDayPicker(
                weekdays: createHabitViewModel.weekdayItems,
                selectedWeekdays: createHabitViewModel.selectedWeekdays,
                onWeekDayItemToggled: {
                    createHabitViewModel.onWeekdayToggled($0)
                }
            )
        }
    }
}

#Preview {
    CreateHabitView(
        createHabitViewModel: CreateHabitViewModel(),
        iconCatalog: BundleHabitIconCatalog()
    )
}
