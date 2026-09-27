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
        }

        weeklyStatistic = makeWeeklyStatistic(from: habits, date: date)
        visibleHabits = habits.filter {
            !weekOccurrences(of: [$0], date: date).isEmpty || !weeklyCountHabits(from: [$0], date: date).isEmpty
        }
    }

    func percentage(for habit: TodayHabit, date: Date = .now) -> Int {
        if case .weeklyCount = habit.habit.schedule.frequency {
            return calculateHabitProgressUseCase
                .execute(habits: weeklyCountHabits(from: [habit], date: date), scope: .weekly)
                .percentage
        }

        return calculateHabitProgressUseCase
            .execute(habits: weekOccurrences(of: [habit], date: date), scope: .daily)
            .percentage
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
            kind: .weekly
        )
    }
}
