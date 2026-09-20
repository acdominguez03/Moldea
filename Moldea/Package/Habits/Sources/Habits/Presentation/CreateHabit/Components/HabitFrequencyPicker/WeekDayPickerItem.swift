//
//  WeekDayPickerItem.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import SwiftUI

struct WeekDayPickerItem: View {
    let weekdayItem: WeekdayItem
    let isSelected: Bool
    let onWeekdayItemToggled: () -> Void

    var body: some View {
        Button(action: onWeekdayItemToggled) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Text(weekdayItem.symbol)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                }
        }
        .buttonStyle(.plain)
        .glassEffect(glass, in: .circle)
        .accessibilityLabel(weekdayItem.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var glass: Glass {
        isSelected
            ? .regular.tint(.accentColor).interactive()
            : .regular.interactive()
    }
}

#Preview {
    @Previewable @State var isSelected: Bool = false

    WeekDayPickerItem(
        weekdayItem: WeekdayItem(id: 1, symbol: "M", name: "Monday"),
        isSelected: isSelected,
        onWeekdayItemToggled: { isSelected = !isSelected }
    )
    .frame(width: 44)
}
