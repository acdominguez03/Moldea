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
    @Previewable @State var createHabitViewModel = CreateHabitViewModel(
        createHabitUseCase: DefaultCreateHabitUseCase(
            repository: SwiftDataHabitRepository(
                modelContainer: try! MoldeaSchema.makeModelContainer(inMemory: true)
            )
        )
    )
    
    WeekDayPicker(
        weekdays: createHabitViewModel.weekdayItems,
        selectedWeekdays: createHabitViewModel.selectedWeekdays,
        onWeekDayItemToggled: { createHabitViewModel.onWeekdayToggled($0) }
    )
}
