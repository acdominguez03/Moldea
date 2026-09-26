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

    private var selection: Binding<HabitFrequencyEnum> {
        Binding(get: { selectedHabitFrequency }, set: { onFrequencyChanged($0) })
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            picker
                .pickerStyle(.menu)
        } else {
            picker
                .pickerStyle(.segmented)
                .labelsHidden()
        }
    }

    private var picker: some View {
        Picker(HabitsTextsEnum.frequency, selection: selection) {
            ForEach(HabitFrequencyEnum.allCases) { frequency in
                Text(frequency.name).tag(frequency)
            }
        }
    }
}


#Preview {
    @Previewable @State var selectedHabitFrequency: HabitFrequencyEnum = .everyDay

    Form {
        HabitFrequencyPicker(
            selectedHabitFrequency: selectedHabitFrequency,
            onFrequencyChanged: { selectedHabitFrequency = $0 }
        )
    }
}
