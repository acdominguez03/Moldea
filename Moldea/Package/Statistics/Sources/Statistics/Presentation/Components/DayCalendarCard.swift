//
//  DayCalendarCard.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI

struct DayCalendarCard: View {
    let dayLetter: String
    let day: Int
    let isSelected: Bool

    init(dayLetter: String, day: Int, isSelected: Bool = false) {
        self.dayLetter = dayLetter
        self.day = day
        self.isSelected = isSelected
    }

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Text(dayLetter)
                .font(.body)

            Text(day, format: .number)
                .font(.body)

            Circle()
                .frame(width: 10, height: 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.clear))
        )
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack {
        DayCalendarCard(dayLetter: "L", day: 14)
        DayCalendarCard(dayLetter: "M", day: 15, isSelected: true)
    }
}
