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

            ProgressBarChart(statistics: monthChartViewModel.data)

            HabitProgressList(habits: monthlyHabits) {
                monthChartViewModel.percentage(for: $0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: chartInput, initial: true) {
            monthChartViewModel.getMonthlyPercentages(habits: monthlyHabits)
        }
    }

    private var chartInput: [Int] {
        monthlyHabits.map(\.completions.count) + [monthlyHabits.count]
    }
}


#Preview {
    MonthChartView(monthChartViewModel: MonthChartViewModel(calculateHabitProgressUseCase: CalculateHabitsProgressUseCase()))
}
