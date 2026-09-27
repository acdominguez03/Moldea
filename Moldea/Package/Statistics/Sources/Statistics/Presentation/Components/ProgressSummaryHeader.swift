//
//  ProgressSummaryHeader.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI

struct ProgressSummaryHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.calendar) private var calendar

    let percentage: Int
    let summary: LocalizedStringResource
    let interval: DateInterval
    let onShowAll: (() -> Void)?

    init(
        percentage: Int,
        summary: LocalizedStringResource,
        interval: DateInterval,
        onShowAll: (() -> Void)? = nil
    ) {
        self.percentage = percentage
        self.summary = summary
        self.interval = interval
        self.onShowAll = onShowAll
    }

    var body: some View {
        let rowLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .lastTextBaseline))

        rowLayout {
            summaryBlock

            if let onShowAll {
                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer()
                }

                Button(StatisticsTextsEnum.showAll, action: onShowAll)
                    .font(.subheadline)
                    .buttonStyle(.borderless)
            }
        }
    }

    private var summaryBlock: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .bottom, spacing: 10))

        return VStack(alignment: .leading, spacing: 4) {
            layout {
                Text(percentage, format: .percent)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text(datesText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var datesText: String {
        let start = interval.start
        let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? start

        if lastDay <= start || calendar.isDate(start, inSameDayAs: lastDay) {
            return start.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
        }

        if spansSeveralWholeMonths(start: start, lastDay: lastDay) {
            return (start..<lastDay).formatted(.interval.month(.abbreviated).year())
        }

        return (start..<lastDay).formatted(.interval.day().month(.abbreviated))
    }

    private func spansSeveralWholeMonths(start: Date, lastDay: Date) -> Bool {
        guard let firstMonth = calendar.dateInterval(of: .month, for: start),
              let lastMonth = calendar.dateInterval(of: .month, for: lastDay) else {
            return false
        }
        return firstMonth.start == start && lastMonth.end == interval.end && firstMonth != lastMonth
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 30) {
        ProgressSummaryHeader(
            percentage: 45,
            summary: StatisticsTextsEnum.weekChartSummary,
            interval: Calendar.current.dateInterval(of: .weekOfYear, for: .now) ?? DateInterval()
        )

        ProgressSummaryHeader(
            percentage: 80,
            summary: StatisticsTextsEnum.selectionSummary,
            interval: Calendar.current.dateInterval(of: .day, for: .now) ?? DateInterval(),
            onShowAll: {}
        )
    }
    .padding()
}
