//
//  TimesADayPicker.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import SwiftUI

struct TimesADayPicker: View {
    let range: ClosedRange<Int>
    let selectedTimesADay: Int
    let onIncrementTimesADay: () -> Void
    let onDecrementTimesADay: () -> Void

    private var value: Binding<Int> {
        Binding(
            get: { selectedTimesADay },
            set: { newValue in
                if newValue > selectedTimesADay {
                    onIncrementTimesADay()
                } else if newValue < selectedTimesADay {
                    onDecrementTimesADay()
                }
            }
        )
    }

    var body: some View {
        Stepper(value: value, in: range) {
            LabeledContent(HabitsTextsEnum.timesADay) {
                Text(selectedTimesADay, format: .number)
                    .monospacedDigit()
            }
        }
    }
}

#Preview() {
    @Previewable @State var timesADay = 1

    Form {
        TimesADayPicker(
            range: 1...20,
            selectedTimesADay: timesADay,
            onIncrementTimesADay: { timesADay += 1 },
            onDecrementTimesADay: { timesADay -= 1 }
        )
    }
}
