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
        self.data = Self.emptyMonth()
        self.summaryInterval = calendar.dateInterval(of: .month, for: .now) ?? DateInterval()
    }

    func getMonthlyPercentages(habits: [TodayHabit], date: Date = .now) {
        let buckets = occurrencesBuilder.monthBuckets(containing: date)
        let occurrencesByWeek = buckets.map {
            occurrencesBuilder.occurrences(of: habits, in: $0, until: date)
        }

        totalProgress = progress(of: occurrencesByWeek.flatMap { $0 })

        for (index, occurrences) in occurrencesByWeek.enumerated() where data.indices.contains(index) {
            data[index].percentage = progress(of: occurrences)
            data[index].interval = buckets[index]
        }

        let selected = selectedStatistic
        if selected == nil {
            selectedStatisticID = nil
        }
        summaryPercentage = selected?.percentage ?? totalProgress
        summaryInterval = selected?.interval
            ?? calendar.dateInterval(of: .month, for: date)
            ?? summaryInterval
        visibleHabits = habits.filter {
            !occurrences(of: [$0], date: date).isEmpty
        }
    }

    func select(_ id: String, habits: [TodayHabit], date: Date = .now) {
        if id == selectedStatisticID {
            selectedStatisticID = nil
        } else if let interval = data.first(where: { $0.id == id })?.interval, interval.start <= date {
            selectedStatisticID = id
        }
        getMonthlyPercentages(habits: habits, date: date)
    }

    func clearSelection(habits: [TodayHabit], date: Date = .now) {
        selectedStatisticID = nil
        getMonthlyPercentages(habits: habits, date: date)
    }

    func percentage(for habit: TodayHabit, date: Date = .now) -> Int {
        progress(of: occurrences(of: [habit], date: date))
    }

    private var selectedStatistic: HabitStatistic? {
        data.first { $0.id == selectedStatisticID }
    }

    private func occurrences(of habits: [TodayHabit], date: Date) -> [TodayHabit] {
        guard let bucket = selectedStatistic?.interval else {
            return occurrencesBuilder.monthOccurrences(of: habits, containing: date, until: date)
        }
        return occurrencesBuilder.occurrences(of: habits, in: bucket, until: date)
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
                accessibilityTitle: String(localized: StatisticsTextsEnum.monthChartWeekAccessibility(number)),
                percentage: 0
            )
        }
    }
}
