//
//  MonthChartViewModel.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import Foundation
import Core

@Observable
final class MonthChartViewModel {
    private(set) var totalProgress: Int = 0
    private(set) var data: [HabitStatistic]

    private let calculateHabitProgressUseCase: CalculateHabitsProgressUseCaseProtocol
    private let occurrencesBuilder: HabitOccurrencesBuilder

    init(
        calculateHabitProgressUseCase: CalculateHabitsProgressUseCaseProtocol,
        calendar: Calendar = .current
    ) {
        self.calculateHabitProgressUseCase = calculateHabitProgressUseCase
        self.occurrencesBuilder = HabitOccurrencesBuilder(calendar: calendar)
        self.data = Self.emptyMonth()
    }

    func getMonthlyPercentages(habits: [TodayHabit], date: Date = .now) {
        let occurrencesByWeek = occurrencesBuilder.monthBuckets(containing: date).map {
            occurrencesBuilder.occurrences(of: habits, in: $0, until: date)
        }

        totalProgress = progress(of: occurrencesByWeek.flatMap { $0 })

        for (index, occurrences) in occurrencesByWeek.enumerated() where data.indices.contains(index) {
            data[index].percentage = progress(of: occurrences)
        }
    }

    func percentage(for habit: TodayHabit, date: Date = .now) -> Int {
        progress(of: occurrencesBuilder.monthOccurrences(of: [habit], containing: date, until: date))
    }

    private func progress(of occurrences: [TodayHabit]) -> Int {
        calculateHabitProgressUseCase
            .execute(habits: occurrences, scope: .all)
            .percentage
    }

    private static func emptyMonth() -> [HabitStatistic] {
        (1...4).map { number in
            HabitStatistic(
                id: "week_\(number)",
                title: String(localized: StatisticsTextsEnum.monthChartWeekMark(number)),
                percentage: 0
            )
        }
    }
}
