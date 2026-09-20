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
    
    var body: some View {
        HStack {
            Text(HabitsTextsEnum.timesADay)
                .font(.body)
            
            Spacer()
            
            Button(action: { onDecrementTimesADay() }) {
                Image(systemName: "minus")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            .disabled(selectedTimesADay <= range.lowerBound)
            .buttonBorderShape(.circle)
            .buttonStyle(.glass)
            
            Text("\(selectedTimesADay)")
                .monospacedDigit()
                .padding(.horizontal, 16)
            
            Button(action: { onIncrementTimesADay() }) {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            .disabled(selectedTimesADay >= range.upperBound)
            .buttonBorderShape(.circle)
            .buttonStyle(.glass)
        }
    }
}

#Preview() {
    TimesADayPicker(
        range: 1...20,
        selectedTimesADay: 0,
        onIncrementTimesADay: {},
        onDecrementTimesADay: {}
    )
}
