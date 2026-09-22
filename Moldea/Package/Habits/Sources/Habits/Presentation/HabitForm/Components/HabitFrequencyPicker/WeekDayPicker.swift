//
//  WeekDayPicker.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import SwiftUI
import Core

struct WeekDayPicker: View {
    let weekdays: [WeekdayItem]
    let selectedWeekdays: Set<Int>
    let onWeekDayItemToggled: (WeekdayItem) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekdays) { weekday in
                WeekDayPickerItem(
                    weekdayItem: weekday,
                    isSelected: selectedWeekdays.contains(weekday.id),
                    onWeekdayItemToggled: { onWeekDayItemToggled(weekday) }
                )
            }
        }
    }
}

#Preview {
    @Previewable @State var habitFormViewModel = HabitFormViewModel(
        createHabitUseCase: DefaultCreateHabitUseCase(
            repository: SwiftDataHabitRepository(
                modelContainer: try! MoldeaSchema.makeModelContainer(inMemory: true)
            )
        ),
        updateHabitUseCase: DefaultUpdateHabitUseCase(
            repository: SwiftDataHabitRepository(
                modelContainer: try! MoldeaSchema.makeModelContainer(inMemory: true)
            )
        )
    )
    
    WeekDayPicker(
        weekdays: habitFormViewModel.weekdayItems,
        selectedWeekdays: habitFormViewModel.selectedWeekdays,
        onWeekDayItemToggled: { habitFormViewModel.onWeekdayToggled($0) }
    )
}
