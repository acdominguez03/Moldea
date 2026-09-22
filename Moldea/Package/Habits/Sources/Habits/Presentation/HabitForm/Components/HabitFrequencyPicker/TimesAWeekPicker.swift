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
    
    var body: some View {
        HStack {
            Text(HabitsTextsEnum.timesAWeek)
                .font(.body)
            
            Spacer()
            
            Button(action: { onDecrementTimesAWeek() }) {
                Image(systemName: "minus")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            .disabled(selectedTimesAWeek <= range.lowerBound)
            .buttonBorderShape(.circle)
            .buttonStyle(.glass)
            
            Text("\(selectedTimesAWeek)")
                .monospacedDigit()
                .padding(.horizontal, 16)
            
            Button(action: { onIncrementTimesAWeek() }) {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            .disabled(selectedTimesAWeek >= range.upperBound)
            .buttonBorderShape(.circle)
            .buttonStyle(.glass)
        }
    }
}

#Preview() {
    TimesAWeekPicker(
        range: 1...7,
        selectedTimesAWeek: 0,
        onIncrementTimesAWeek: {},
        onDecrementTimesAWeek: {}
    )
}
