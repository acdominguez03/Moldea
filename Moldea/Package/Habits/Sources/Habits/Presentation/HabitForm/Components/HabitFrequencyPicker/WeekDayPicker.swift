//
//  WeekDayPicker.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import SwiftUI
import Core

struct WeekDayPicker: View {
    private static let accessibilityColumns = 4

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let weekdays: [WeekdayItem]
    let selectedWeekdays: Set<Int>
    let onWeekDayItemToggled: (WeekdayItem) -> Void

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: Self.accessibilityColumns),
                spacing: 8
            ) {
                items
            }
        } else {
            HStack(spacing: 8) {
                items
            }
        }
    }

    private var items: some View {
        ForEach(weekdays) { weekday in
            WeekDayPickerItem(
                weekdayItem: weekday,
                isSelected: selectedWeekdays.contains(weekday.id),
                onWeekdayItemToggled: { onWeekDayItemToggled(weekday) }
            )
        }
    }
}

#Preview {
    @Previewable @State var habitFormViewModel = HabitsDependencies.preview.makeHabitFormViewModel()

    WeekDayPicker(
        weekdays: habitFormViewModel.weekdayItems,
        selectedWeekdays: habitFormViewModel.selectedWeekdays,
        onWeekDayItemToggled: { habitFormViewModel.onWeekdayToggled($0) }
    )
}
