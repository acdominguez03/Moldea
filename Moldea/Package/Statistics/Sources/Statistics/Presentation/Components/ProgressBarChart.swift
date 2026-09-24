//
//  ProgressBarChart.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI
import Charts

struct ProgressBarChart: View {
    let statistics: [HabitStatistic]

    init(statistics: [HabitStatistic]) {
        self.statistics = statistics
    }

    var body: some View {
        Chart(statistics) { statistic in
            BarMark(
                x: .value("Period", statistic.id),
                y: .value("Percentage", statistic.percentage)
            )
            .foregroundStyle(by: .value("Color", statistic.color))
            .annotation(position: .top) {
                Text(statistic.percentage, format: .number)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .annotation(position: .bottom) {
                Text(statistic.title)
                    .font(.caption)
                    .fontWeight(statistic.kind == .weekly ? .semibold : .medium)
                    .foregroundStyle(statistic.kind == .weekly ? Color.accentColor : .secondary)
            }
        }
        .chartForegroundStyleScale([
            "gray_500": Color.gray.opacity(0.4),
            "gray_800": Color.gray.opacity(0.7),
            "gray": Color.gray,
            "weekly": Color.accentColor
        ])
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 200)
    }
}

#Preview {
    ProgressBarChart(statistics: [
        HabitStatistic(id: "a", title: "L", percentage: 40),
        HabitStatistic(id: "b", title: "M", percentage: 70),
        HabitStatistic(id: "c", title: "X", percentage: 100),
        HabitStatistic(id: "weekly", title: "Sem", percentage: 50, kind: .weekly)
    ])
}
