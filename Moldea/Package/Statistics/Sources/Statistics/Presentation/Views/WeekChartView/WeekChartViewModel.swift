//
//  WeekChartViewModel.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import Foundation
import Core

@Observable
final class WeekChartViewModel {
    private(set) var totalProgress: Int = 0
    private(set) var weeklyStatistic: HabitStatistic?
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
        self.data = Self.emptyWeek(calendar: calendar)
        self.summaryInterval = calendar.dateInterval(of: .weekOfYear, for: .now) ?? DateInterval()
    }

    var chartData: [HabitStatistic] {
        data + [weeklyStatistic].compactMap { $0 }
    }

    func getWeeklyPercentages(habits: [TodayHabit], date: Date = .now) {
        let wholeWeek = weekOccurrences(of: habits, date: date) + weeklyCountHabits(from: habits, date: date)
        totalProgress = calculateHabitProgressUseCase
            .execute(habits: wholeWeek, scope: .all)
            .percentage

        for (index, day) in weekDays(containing: date).enumerated() where data.indices.contains(index) {
            let scheduled = occurrencesBuilder.occurrences(of: habits, on: day)
            data[index].percentage = calculateHabitProgressUseCase
                .execute(habits: scheduled, scope: .daily)
                .percentage
            data[index].interval = calendar.dateInterval(of: .day, for: day)
        }

        weeklyStatistic = makeWeeklyStatistic(from: habits, date: date)

        let selected = selectedStatistic
        if selected == nil {
            selectedStatisticID = nil
        }
        summaryPercentage = selected?.percentage ?? totalProgress
        summaryInterval = selected?.interval
            ?? calendar.dateInterval(of: .weekOfYear, for: date)
            ?? summaryInterval
        visibleHabits = habits.filter {
            !occurrences(of: $0, date: date).habits.isEmpty
        }
    }

    func select(_ id: String, habits: [TodayHabit], date: Date = .now) {
        if id == selectedStatisticID {
            selectedStatisticID = nil
        } else if let interval = chartData.first(where: { $0.id == id })?.interval, interval.start <= date {
            selectedStatisticID = id
        }
        getWeeklyPercentages(habits: habits, date: date)
    }

    func clearSelection(habits: [TodayHabit], date: Date = .now) {
        selectedStatisticID = nil
        getWeeklyPercentages(habits: habits, date: date)
    }

    func percentage(for habit: TodayHabit, date: Date = .now) -> Int {
        let occurrences = occurrences(of: habit, date: date)
        return calculateHabitProgressUseCase
            .execute(habits: occurrences.habits, scope: occurrences.scope)
            .percentage
    }

    private var selectedStatistic: HabitStatistic? {
        chartData.first { $0.id == selectedStatisticID }
    }

    private func occurrences(
        of habit: TodayHabit,
        date: Date
    ) -> (habits: [TodayHabit], scope: HabitProgressScopeEnum) {
        switch selectedStatistic {
        case .some(let statistic) where statistic.kind == .weekly:
            return (weeklyCountHabits(from: [habit], date: date), .weekly)
        case .some(let statistic):
            guard let day = statistic.interval?.start else {
                return ([], .daily)
            }
            return (occurrencesBuilder.occurrences(of: [habit], on: day), .daily)
        case .none:
            if case .weeklyCount = habit.habit.schedule.frequency {
                return (weeklyCountHabits(from: [habit], date: date), .weekly)
            }
            return (weekOccurrences(of: [habit], date: date), .daily)
        }
    }

    private static func emptyWeek(calendar: Calendar) -> [HabitStatistic] {
        let symbols = calendar.veryShortWeekdaySymbols
        let names = calendar.standaloneWeekdaySymbols
        return (0..<symbols.count).map { offset in
            let weekday = (calendar.firstWeekday - 1 + offset) % symbols.count
            return HabitStatistic(
                id: "day_\(weekday)",
                title: symbols[weekday],
                accessibilityTitle: names[weekday],
                percentage: 0
            )
        }
    }

    private func weekDays(containing date: Date) -> [Date] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }
        return (0..<data.count).compactMap {
            calendar.date(byAdding: .day, value: $0, to: week.start)
        }
    }

    private func weekOccurrences(of habits: [TodayHabit], date: Date) -> [TodayHabit] {
        weekDays(containing: date).flatMap {
            occurrencesBuilder.occurrences(of: habits, on: $0)
        }
    }

    private func weeklyCountHabits(from habits: [TodayHabit], date: Date) -> [TodayHabit] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }
        return habits.compactMap {
            occurrencesBuilder.weeklyOccurrence(of: $0, in: week)
        }
    }

    private func makeWeeklyStatistic(from habits: [TodayHabit], date: Date) -> HabitStatistic? {
        let weeklyHabits = weeklyCountHabits(from: habits, date: date)

        guard !weeklyHabits.isEmpty else {
            return nil
        }

        let progress = calculateHabitProgressUseCase.execute(habits: weeklyHabits, scope: .weekly)
        return HabitStatistic(
            id: "weekly",
            title: String(localized: StatisticsTextsEnum.weekChartWeeklyMark),
            accessibilityTitle: String(localized: StatisticsTextsEnum.weekChartWeeklyAccessibility),
            percentage: progress.percentage,
            kind: .weekly,
            interval: calendar.dateInterval(of: .weekOfYear, for: date)
        )
    }
}
