//
//  ProgressChartDescriptor.swift
//  Statistics
//

import SwiftUI
import Accessibility

struct ProgressChartDescriptor: AXChartDescriptorRepresentable {
    let title: String
    let statistics: [HabitStatistic]

    func makeChartDescriptor() -> AXChartDescriptor {
        let periodAxis = AXCategoricalDataAxisDescriptor(
            title: String(localized: StatisticsTextsEnum.chartAxisPeriod),
            categoryOrder: statistics.map(\.accessibilityTitle)
        )

        let percentageAxis = AXNumericDataAxisDescriptor(
            title: String(localized: StatisticsTextsEnum.chartAxisPercentage),
            range: 0...100,
            gridlinePositions: [0, 50, 100]
        ) { value in
            (value / 100).formatted(.percent.precision(.fractionLength(0)))
        }

        let series = AXDataSeriesDescriptor(
            name: title,
            isContinuous: false,
            dataPoints: statistics.map { statistic in
                AXDataPoint(x: statistic.accessibilityTitle, y: Double(statistic.percentage))
            }
        )

        return AXChartDescriptor(
            title: title,
            summary: nil,
            xAxis: periodAxis,
            yAxis: percentageAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}
