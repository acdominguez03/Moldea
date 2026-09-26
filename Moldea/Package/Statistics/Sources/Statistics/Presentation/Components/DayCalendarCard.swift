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

    @ScaledMetric(relativeTo: .body) private var dotSize: CGFloat = 10

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
                .frame(width: dotSize, height: dotSize)
                .accessibilityHidden(true)
        }
        .fontWeight(isSelected ? .bold : .regular)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.clear))
        )
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(.primary, lineWidth: 1.5)
            }
        }
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
