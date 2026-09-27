//
//  DayChartView.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI
import Core

struct DayChartView: View {

    @AllHabitsInPeriodQuery(DayChartViewModel.period()) private var lastDaysHabits: [TodayHabit]

    @State private var dayChartViewModel: DayChartViewModel

    init(dayChartViewModel: DayChartViewModel) {
        self.dayChartViewModel = dayChartViewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 5) {
                    ForEach(dayChartViewModel.days) { day in
                        Button {
                            dayChartViewModel.select(day, habits: lastDaysHabits)
                        } label: {
                            DayCalendarCard(
                                dayLetter: day.letter,
                                day: day.number,
                                isSelected: day.date == dayChartViewModel.selectedDay
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            Text(day.date, format: .dateTime.weekday(.wide).day().month(.wide))
                        )
                        .accessibilityAddTraits(day.date == dayChartViewModel.selectedDay ? .isSelected : [])
                    }
                }
            }
            .defaultScrollAnchor(.trailing)
            .scrollIndicators(.hidden)
            .fixedSize(horizontal: false, vertical: true)

            ProgressSummaryHeader(
                percentage: dayChartViewModel.totalProgress,
                summary: StatisticsTextsEnum.dayChartSummary,
                interval: dayChartViewModel.selectedInterval
            )

            HabitProgressList(habits: dayChartViewModel.dayHabits) {
                dayChartViewModel.percentage(for: $0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: chartInput, initial: true) {
            dayChartViewModel.getDailyPercentages(habits: lastDaysHabits)
        }
    }

    private var chartInput: [Int] {
        lastDaysHabits.map(\.completions.count) + [lastDaysHabits.count]
    }
}


#Preview(traits: .moldea) {
    DayChartView(dayChartViewModel: StatisticsDependencies.preview.makeDayChartViewModel())
}
