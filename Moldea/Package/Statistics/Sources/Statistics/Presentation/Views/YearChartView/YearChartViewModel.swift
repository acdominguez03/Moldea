//
//  YearChartViewModel.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import Foundation
import Core

@Observable
final class YearChartViewModel {
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
        self.data = Self.emptyYear(calendar: calendar)
    }

    func getYearlyPercentages(habits: [TodayHabit], date: Date = .now) {
        let occurrencesByMonth = occurrencesBuilder.monthStarts(ofYearContaining: date).map {
            occurrencesBuilder.monthOccurrences(of: habits, containing: $0, until: date)
        }

        totalProgress = progress(of: occurrencesByMonth.flatMap { $0 })

        for (index, occurrences) in occurrencesByMonth.enumerated() where data.indices.contains(index) {
            data[index].percentage = progress(of: occurrences)
        }
    }

    func percentage(for habit: TodayHabit, date: Date = .now) -> Int {
        let occurrences = occurrencesBuilder.monthStarts(ofYearContaining: date).flatMap {
            occurrencesBuilder.monthOccurrences(of: [habit], containing: $0, until: date)
        }
        return progress(of: occurrences)
    }

    private func progress(of occurrences: [TodayHabit]) -> Int {
        calculateHabitProgressUseCase
            .execute(habits: occurrences, scope: .all)
            .percentage
    }

    private static func emptyYear(calendar: Calendar) -> [HabitStatistic] {
        let names = calendar.standaloneMonthSymbols
        return calendar.veryShortStandaloneMonthSymbols.enumerated().map { index, symbol in
            HabitStatistic(
                id: "month_\(index + 1)",
                title: symbol,
                accessibilityTitle: names[index],
                percentage: 0
            )
        }
    }
}
