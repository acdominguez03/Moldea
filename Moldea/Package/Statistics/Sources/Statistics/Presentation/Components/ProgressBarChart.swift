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
    let selectedID: String?
    let onSelect: (String) -> Void

    init(
        title: LocalizedStringResource,
        statistics: [HabitStatistic],
        selectedID: String? = nil,
        onSelect: @escaping (String) -> Void = { _ in }
    ) {
        self.title = title
        self.statistics = statistics
        self.selectedID = selectedID
        self.onSelect = onSelect
    }

    var body: some View {
        Chart(statistics) { statistic in
            BarMark(
                x: .value(String(localized: StatisticsTextsEnum.chartAxisPeriod), statistic.id),
                y: .value(String(localized: StatisticsTextsEnum.chartAxisPercentage), statistic.percentage)
            )
            .foregroundStyle(by: .value("Tier", statistic.tier.rawValue))
            .opacity(isDimmed(statistic) ? 0.4 : 1)
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
                    .fontWeight(labelWeight(of: statistic))
                    .foregroundStyle(labelStyle(of: statistic))
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
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let plotFrame = proxy.plotFrame,
                              let id = proxy.value(atX: location.x - geometry[plotFrame].origin.x, as: String.self) else {
                            return
                        }
                        onSelect(id)
                    }
                    .accessibilityHidden(true)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityChartDescriptor(
            ProgressChartDescriptor(title: String(localized: title), statistics: statistics)
        )
    }

    private func isDimmed(_ statistic: HabitStatistic) -> Bool {
        selectedID != nil && selectedID != statistic.id
    }

    private func labelWeight(of statistic: HabitStatistic) -> Font.Weight {
        statistic.kind == .weekly || statistic.id == selectedID ? .semibold : .medium
    }

    private func labelStyle(of statistic: HabitStatistic) -> Color {
        if statistic.kind == .weekly {
            return .accentColor
        }
        return statistic.id == selectedID ? .primary : .secondary
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
    ProgressBarChart(
        title: StatisticsTextsEnum.chartTitleWeek,
        statistics: [
            HabitStatistic(id: "a", title: "L", accessibilityTitle: "Lunes", percentage: 40),
            HabitStatistic(id: "b", title: "M", accessibilityTitle: "Martes", percentage: 70),
            HabitStatistic(id: "c", title: "X", accessibilityTitle: "Miércoles", percentage: 100),
            HabitStatistic(id: "weekly", title: "Sem", accessibilityTitle: "Objetivo semanal", percentage: 50, kind: .weekly)
        ],
        selectedID: "b"
    )
}
