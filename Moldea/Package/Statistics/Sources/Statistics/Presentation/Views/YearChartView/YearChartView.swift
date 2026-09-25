//
//  YearChartView.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI
import Core

struct YearChartView: View {

    @AllHabitsInPeriodQuery(.year) private var yearlyHabits: [TodayHabit]

    @State private var yearChartViewModel: YearChartViewModel

    init(yearChartViewModel: YearChartViewModel) {
        self.yearChartViewModel = yearChartViewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProgressSummaryHeader(
                percentage: yearChartViewModel.totalProgress,
                summary: StatisticsTextsEnum.yearChartSummary
            )

            ProgressBarChart(statistics: yearChartViewModel.data)

            HabitProgressList(habits: yearlyHabits) {
                yearChartViewModel.percentage(for: $0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: chartInput, initial: true) {
            yearChartViewModel.getYearlyPercentages(habits: yearlyHabits)
        }
    }

    private var chartInput: [Int] {
        yearlyHabits.map(\.completions.count) + [yearlyHabits.count]
    }
}


#Preview(traits: .moldea) {
    YearChartView(yearChartViewModel: StatisticsDependencies.preview.makeYearChartViewModel())
}
