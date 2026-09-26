//
//  TimesAWeekPicker.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import SwiftUI

struct TimesAWeekPicker: View {
    let range: ClosedRange<Int>
    let selectedTimesAWeek: Int
    let onIncrementTimesAWeek: () -> Void
    let onDecrementTimesAWeek: () -> Void

    private var value: Binding<Int> {
        Binding(
            get: { selectedTimesAWeek },
            set: { newValue in
                if newValue > selectedTimesAWeek {
                    onIncrementTimesAWeek()
                } else if newValue < selectedTimesAWeek {
                    onDecrementTimesAWeek()
                }
            }
        )
    }

    var body: some View {
        Stepper(value: value, in: range) {
            LabeledContent(HabitsTextsEnum.timesAWeek) {
                Text(selectedTimesAWeek, format: .number)
                    .monospacedDigit()
            }
        }
    }
}

#Preview() {
    @Previewable @State var timesAWeek = 1

    Form {
        TimesAWeekPicker(
            range: 1...7,
            selectedTimesAWeek: timesAWeek,
            onIncrementTimesAWeek: { timesAWeek += 1 },
            onDecrementTimesAWeek: { timesAWeek -= 1 }
        )
    }
}
