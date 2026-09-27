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
                percentage: yearChartViewModel.summaryPercentage,
                summary: isFiltered ? StatisticsTextsEnum.selectionSummary : StatisticsTextsEnum.yearChartSummary,
                interval: yearChartViewModel.summaryInterval,
                onShowAll: isFiltered ? { yearChartViewModel.clearSelection(habits: yearlyHabits) } : nil
            )

            ProgressBarChart(
                title: StatisticsTextsEnum.chartTitleYear,
                statistics: yearChartViewModel.data,
                selectedID: yearChartViewModel.selectedStatisticID
            ) {
                yearChartViewModel.select($0, habits: yearlyHabits)
            }

            HabitProgressList(habits: yearChartViewModel.visibleHabits) {
                yearChartViewModel.percentage(for: $0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: chartInput, initial: true) {
            yearChartViewModel.getYearlyPercentages(habits: yearlyHabits)
        }
    }

    private var isFiltered: Bool {
        yearChartViewModel.selectedStatisticID != nil
    }

    private var chartInput: [Int] {
        yearlyHabits.map(\.completions.count)
            + yearlyHabits.map(\.habit.inactivePeriods.count)
            + yearlyHabits.map { $0.habit.isActive ? 1 : 0 }
            + [yearlyHabits.count]
    }
}


#Preview(traits: .moldea) {
    YearChartView(yearChartViewModel: StatisticsDependencies.preview.makeYearChartViewModel())
}
