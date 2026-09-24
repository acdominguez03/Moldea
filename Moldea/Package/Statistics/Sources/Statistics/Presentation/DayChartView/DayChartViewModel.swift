//
//  DayChartViewModel.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import Foundation
import Core

@Observable
final class DayChartViewModel {
    static let numberOfDays = 10

    private(set) var days: [StatisticsDay]
    private(set) var selectedDay: Date
    private(set) var totalProgress: Int = 0
    private(set) var dayHabits: [TodayHabit] = []

    private let calculateHabitProgressUseCase: CalculateHabitsProgressUseCaseProtocol
    private let occurrencesBuilder: HabitOccurrencesBuilder

    init(
        calculateHabitProgressUseCase: CalculateHabitsProgressUseCaseProtocol,
        calendar: Calendar = .current,
        today: Date = .now
    ) {
        self.calculateHabitProgressUseCase = calculateHabitProgressUseCase
        self.occurrencesBuilder = HabitOccurrencesBuilder(calendar: calendar)
        self.selectedDay = calendar.startOfDay(for: today)
        self.days = occurrencesBuilder.lastDays(Self.numberOfDays, until: today).map { date in
            StatisticsDay(
                date: date,
                letter: calendar.veryShortStandaloneWeekdaySymbols[calendar.component(.weekday, from: date) - 1],
                number: calendar.component(.day, from: date)
            )
        }
    }

    static func period(until today: Date = .now, calendar: Calendar = .current) -> DateInterval {
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today)) ?? today
        let start = calendar.date(byAdding: .day, value: -numberOfDays, to: end) ?? end
        return DateInterval(start: start, end: end)
    }

    func select(_ day: StatisticsDay, habits: [TodayHabit]) {
        selectedDay = day.date
        getDailyPercentages(habits: habits)
    }

    func getDailyPercentages(habits: [TodayHabit]) {
        dayHabits = occurrencesBuilder.occurrences(of: habits, on: selectedDay)
        totalProgress = calculateHabitProgressUseCase
            .execute(habits: dayHabits, scope: .daily)
            .percentage
    }

    func percentage(for habit: TodayHabit) -> Int {
        calculateHabitProgressUseCase
            .execute(habits: [habit], scope: .daily)
            .percentage
    }
}
