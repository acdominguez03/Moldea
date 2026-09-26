//
//  HabitProgressCard.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI

struct HabitProgressCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var dotSize: CGFloat = 10

    let color: Color
    let name: String
    let percentage: Int

    init(color: Color, name: String, percentage: Int) {
        self.color = color
        self.name = name
        self.percentage = percentage
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        dot
                        nameText
                    }

                    HStack(spacing: 10) {
                        progressBar
                        percentageText
                    }
                }
            } else {
                HStack(spacing: 10) {
                    dot
                    nameText

                    Spacer()

                    progressBar
                        .frame(maxWidth: 100)

                    percentageText
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(Text(percentage, format: .percent))
    }

    private var dot: some View {
        Circle()
            .frame(width: dotSize, height: dotSize)
            .foregroundStyle(color)
    }

    private var nameText: some View {
        Text(name)
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
    }

    private var progressBar: some View {
        ProgressView(value: Double(percentage), total: 100)
            .progressViewStyle(.linear)
            .tint(color)
    }

    private var percentageText: some View {
        Text(100, format: .percent)
            .hidden()
            .overlay(alignment: .trailing) {
                Text(percentage, format: .percent)
            }
            .font(.body)
            .fontWeight(.medium)
            .monospacedDigit()
    }
}

#Preview {
    HabitProgressCard(color: .red, name: "Correr", percentage: 75)
}
