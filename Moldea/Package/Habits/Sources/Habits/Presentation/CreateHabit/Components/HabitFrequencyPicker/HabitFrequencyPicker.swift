//
//  FrequencyPicker.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import SwiftUI

struct HabitFrequencyPicker: View {
    let selectedHabitFrequency: HabitFrequencyEnum
    let onFrequencyChanged: (HabitFrequencyEnum) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(HabitFrequencyEnum.allCases) { frequency in
                HabitFrequencyPickerItem(
                    frequency: frequency,
                    isSelected: selectedHabitFrequency == frequency,
                    action: {
                        onFrequencyChanged(frequency)
                    }
                )
            }
        }
        .animation(.snappy, value: selectedHabitFrequency)
    }
}


#Preview {
    @Previewable @State var selectedHabitFrequency: HabitFrequencyEnum = .everyDay
    
    HabitFrequencyPicker(
        selectedHabitFrequency: .everyDay, onFrequencyChanged: {
            selectedHabitFrequency = $0
        }
    )
}
