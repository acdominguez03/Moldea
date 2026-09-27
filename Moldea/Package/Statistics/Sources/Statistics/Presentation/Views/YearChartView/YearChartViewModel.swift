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
    private(set) var visibleHabits: [TodayHabit] = []
    private(set) var selectedStatisticID: String?
    private(set) var summaryPercentage: Int = 0
    private(set) var summaryInterval: DateInterval

    private let calculateHabitProgressUseCase: CalculateHabitsProgressUseCaseProtocol
    private let calendar: Calendar
    private let occurrencesBuilder: HabitOccurrencesBuilder

    init(
        calculateHabitProgressUseCase: CalculateHabitsProgressUseCaseProtocol,
        calendar: Calendar = .current
    ) {
        self.calculateHabitProgressUseCase = calculateHabitProgressUseCase
        self.calendar = calendar
        self.occurrencesBuilder = HabitOccurrencesBuilder(calendar: calendar)
        self.data = Self.emptyYear(calendar: calendar)
        self.summaryInterval = calendar.dateInterval(of: .year, for: .now) ?? DateInterval()
    }

    func getYearlyPercentages(habits: [TodayHabit], date: Date = .now) {
        let monthStarts = occurrencesBuilder.monthStarts(ofYearContaining: date)
        let occurrencesByMonth = monthStarts.map {
            occurrencesBuilder.monthOccurrences(of: habits, containing: $0, until: date)
        }

        totalProgress = progress(of: occurrencesByMonth.flatMap { $0 })

        for (index, occurrences) in occurrencesByMonth.enumerated() where data.indices.contains(index) {
            data[index].percentage = progress(of: occurrences)
            data[index].interval = calendar.dateInterval(of: .month, for: monthStarts[index])
        }

        let selected = selectedStatistic
        if selected == nil {
            selectedStatisticID = nil
        }
        summaryPercentage = selected?.percentage ?? totalProgress
        summaryInterval = selected?.interval
            ?? calendar.dateInterval(of: .year, for: date)
            ?? summaryInterval
        visibleHabits = habits.filter {
            !occurrences(of: $0, date: date).isEmpty
        }
    }

    func select(_ id: String, habits: [TodayHabit], date: Date = .now) {
        if id == selectedStatisticID {
            selectedStatisticID = nil
        } else if let interval = data.first(where: { $0.id == id })?.interval, interval.start <= date {
            selectedStatisticID = id
        }
        getYearlyPercentages(habits: habits, date: date)
    }

    func clearSelection(habits: [TodayHabit], date: Date = .now) {
        selectedStatisticID = nil
        getYearlyPercentages(habits: habits, date: date)
    }

    func percentage(for habit: TodayHabit, date: Date = .now) -> Int {
        progress(of: occurrences(of: habit, date: date))
    }

    private var selectedStatistic: HabitStatistic? {
        data.first { $0.id == selectedStatisticID }
    }

    private func occurrences(of habit: TodayHabit, date: Date) -> [TodayHabit] {
        if let month = selectedStatistic?.interval {
            return occurrencesBuilder.monthOccurrences(of: [habit], containing: month.start, until: date)
        }
        return occurrencesBuilder.monthStarts(ofYearContaining: date).flatMap {
            occurrencesBuilder.monthOccurrences(of: [habit], containing: $0, until: date)
        }
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
