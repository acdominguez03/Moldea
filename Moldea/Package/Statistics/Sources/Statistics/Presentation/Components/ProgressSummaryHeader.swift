//
//  ProgressSummaryHeader.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI

struct ProgressSummaryHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let percentage: Int
    let summary: LocalizedStringResource

    init(percentage: Int, summary: LocalizedStringResource) {
        self.percentage = percentage
        self.summary = summary
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .bottom, spacing: 10))

        layout {
            Text(percentage, format: .percent)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    ProgressSummaryHeader(percentage: 45, summary: StatisticsTextsEnum.weekChartSummary)
}
