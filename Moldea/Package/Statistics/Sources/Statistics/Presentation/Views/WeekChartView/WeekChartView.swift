//
//  WeekChartView.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI
import Core

struct WeekChartView: View {

    @AllHabitsInPeriodQuery(.weekOfYear) private var weeklyHabits: [TodayHabit]
    
    @State private var weekChartViewModel: WeekChartViewModel
    
    init(weekChartViewModel: WeekChartViewModel) {
        self.weekChartViewModel = weekChartViewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ProgressSummaryHeader(
                percentage: weekChartViewModel.totalProgress,
                summary: StatisticsTextsEnum.weekChartSummary
            )

            ProgressBarChart(title: StatisticsTextsEnum.chartTitleWeek, statistics: weekChartViewModel.chartData)
            
            HabitProgressList(habits: weekChartViewModel.visibleHabits) {
                weekChartViewModel.percentage(for: $0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: chartInput, initial: true) {
            weekChartViewModel.getWeeklyPercentages(habits: weeklyHabits)
        }
    }
    
    private var chartInput: [Int] {
        weeklyHabits.map(\.completions.count)
            + weeklyHabits.map(\.habit.inactivePeriods.count)
            + weeklyHabits.map { $0.habit.isActive ? 1 : 0 }
            + [weeklyHabits.count]
    }
}


#Preview(traits: .moldea) {
    WeekChartView(weekChartViewModel: StatisticsDependencies.preview.makeWeekChartViewModel())
}
