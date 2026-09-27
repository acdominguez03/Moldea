//
//  MonthChartView.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI
import Core

struct MonthChartView: View {

    @AllHabitsInPeriodQuery(.month) private var monthlyHabits: [TodayHabit]

    @State private var monthChartViewModel: MonthChartViewModel

    init(monthChartViewModel: MonthChartViewModel) {
        self.monthChartViewModel = monthChartViewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProgressSummaryHeader(
                percentage: monthChartViewModel.totalProgress,
                summary: StatisticsTextsEnum.monthChartSummary
            )

            ProgressBarChart(title: StatisticsTextsEnum.chartTitleMonth, statistics: monthChartViewModel.data)

            HabitProgressList(habits: monthChartViewModel.visibleHabits) {
                monthChartViewModel.percentage(for: $0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: chartInput, initial: true) {
            monthChartViewModel.getMonthlyPercentages(habits: monthlyHabits)
        }
    }

    private var chartInput: [Int] {
        monthlyHabits.map(\.completions.count)
            + monthlyHabits.map(\.habit.inactivePeriods.count)
            + monthlyHabits.map { $0.habit.isActive ? 1 : 0 }
            + [monthlyHabits.count]
    }
}


#Preview(traits: .moldea) {
    MonthChartView(monthChartViewModel: StatisticsDependencies.preview.makeMonthChartViewModel())
}
