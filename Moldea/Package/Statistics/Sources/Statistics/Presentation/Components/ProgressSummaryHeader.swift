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
        HStack(spacing: 5) {
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
    }
}

#Preview {
    ProgressSummaryHeader(percentage: 45, summary: StatisticsTextsEnum.weekChartSummary)
}
