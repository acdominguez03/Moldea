//
//  ProgressBarChart.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI
import Charts
import Core

struct ProgressBarChart: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: LocalizedStringResource
    let statistics: [HabitStatistic]

    init(title: LocalizedStringResource, statistics: [HabitStatistic]) {
        self.title = title
        self.statistics = statistics
    }

    var body: some View {
        Chart(statistics) { statistic in
            BarMark(
                x: .value(String(localized: StatisticsTextsEnum.chartAxisPeriod), statistic.id),
                y: .value(String(localized: StatisticsTextsEnum.chartAxisPercentage), statistic.percentage)
            )
            .foregroundStyle(by: .value("Tier", statistic.tier.rawValue))
            .accessibilityLabel(statistic.accessibilityTitle)
            .accessibilityValue(
                (Double(statistic.percentage) / 100).formatted(.percent.precision(.fractionLength(0)))
            )
            .annotation(position: .top) {
                Text(statistic.percentage, format: .number)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .annotation(position: .bottom) {
                Text(statistic.title)
                    .font(.caption)
                    .fontWeight(statistic.kind == .weekly ? .semibold : .medium)
                    .foregroundStyle(statistic.kind == .weekly ? Color.accentColor : .secondary)
                    .accessibilityHidden(true)
            }
        }
        .chartForegroundStyleScale([
            HabitStatistic.Tier.low.rawValue: tierColor(.low),
            HabitStatistic.Tier.medium.rawValue: tierColor(.medium),
            HabitStatistic.Tier.high.rawValue: tierColor(.high),
            HabitStatistic.Tier.weekly.rawValue: Color.accentColor
        ])
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityChartDescriptor(
            ProgressChartDescriptor(title: String(localized: title), statistics: statistics)
        )
    }

    private func tierColor(_ tier: HabitStatistic.Tier) -> Color {
        let hex: String
        switch (tier, colorScheme) {
        case (.low, .dark): hex = "#7C7C80"
        case (.low, _): hex = "#8A8A8E"
        case (.medium, .dark): hex = "#AEAEB2"
        case (.medium, _): hex = "#5E5E63"
        case (.high, .dark), (.weekly, .dark): hex = "#F2F2F7"
        case (.high, _), (.weekly, _): hex = "#1C1C1E"
        }
        return HexColorConverter.color(fromHex: hex) ?? .gray
    }
}

#Preview {
    ProgressBarChart(title: StatisticsTextsEnum.chartTitleWeek, statistics: [
        HabitStatistic(id: "a", title: "L", accessibilityTitle: "Lunes", percentage: 40),
        HabitStatistic(id: "b", title: "M", accessibilityTitle: "Martes", percentage: 70),
        HabitStatistic(id: "c", title: "X", accessibilityTitle: "Miércoles", percentage: 100),
        HabitStatistic(id: "weekly", title: "Sem", accessibilityTitle: "Objetivo semanal", percentage: 50, kind: .weekly)
    ])
}
