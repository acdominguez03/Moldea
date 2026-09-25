//
//  ProgressSummaryHeader.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI

struct ProgressSummaryHeader: View {
    let percentage: Int
    let summary: LocalizedStringResource

    init(percentage: Int, summary: LocalizedStringResource) {
        self.percentage = percentage
        self.summary = summary
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Text(percentage, format: .percent)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(summary)
                .font(.footnote)
                .fontWeight(.light)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .lineLimit(1)
    }
}

#Preview {
    ProgressSummaryHeader(percentage: 45, summary: StatisticsTextsEnum.weekChartSummary)
}
