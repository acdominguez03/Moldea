//
//  StatisticsView.swift
//  Statistics
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Core

public struct StatisticsView: View {
    @Environment(\.statisticsDependencies) private var dependencies

    @HabitsQuery private var habits: [Habit]

    @State private var filterSelected: StatisticsFilterEnum = .day

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView {
                        Label(StatisticsTextsEnum.emptyState, systemImage: "chart.bar")
                    }
                } else {
                    VStack {
                        Picker(StatisticsTextsEnum.screenTitle, selection: $filterSelected) {
                            Text(StatisticsTextsEnum.statisticsFilterDay)
                                .tag(StatisticsFilterEnum.day)

                            Text(StatisticsTextsEnum.statisticsFilterWeek)
                                .tag(StatisticsFilterEnum.week)

                            Text(StatisticsTextsEnum.statisticsFilterMonth)
                                .tag(StatisticsFilterEnum.month)

                            Text(StatisticsTextsEnum.statisticsFilterYear)
                                .tag(StatisticsFilterEnum.year)
                        }
                        .pickerStyle(.segmented)

                        filterContent
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(20)
                }
            }
            .navigationTitle(StatisticsTextsEnum.screenTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private var filterContent: some View {
        switch filterSelected {
        case .day:
            DayChartView(dayChartViewModel: dependencies.makeDayChartViewModel())
        case .week:
            WeekChartView(weekChartViewModel: dependencies.makeWeekChartViewModel())
        case .month:
            MonthChartView(monthChartViewModel: dependencies.makeMonthChartViewModel())
        case .year:
            YearChartView(yearChartViewModel: dependencies.makeYearChartViewModel())
        }
    }
}

#Preview(traits: .moldea) {
    StatisticsView()
}
