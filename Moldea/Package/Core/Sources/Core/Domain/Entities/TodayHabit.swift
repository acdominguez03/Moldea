//
//  TodayHabit.swift
//  Core
//
//  Created by Andrés on 23/09/2026.
//

import Foundation

public struct TodayHabit: Identifiable, Sendable {
    public let habit: Habit
    public let completions: [HabitCompletion]
    public let referenceDay: Date

    private let calendar: Calendar

    public init(
        habit: Habit,
        completions: [HabitCompletion],
        referenceDay: Date,
        calendar: Calendar = .current
    ) {
        self.habit = habit
        self.completions = completions
        self.referenceDay = referenceDay
        self.calendar = calendar
    }

    public var id: Habit.ID { habit.id }

    public var completedToday: Int {
        completions
            .filter { calendar.isDate($0.day, inSameDayAs: referenceDay) }
            .count
    }

    public var isCompletedToday: Bool {
        completedToday >= repetitionsPerDay
    }

    public var completedDaysThisWeek: Int {
        let completedDays = Dictionary(grouping: completions) { calendar.startOfDay(for: $0.day) }
            .values
            .filter { $0.count >= repetitionsPerDay }
            .count

        guard case .weeklyCount(let timesPerWeek) = habit.schedule.frequency else {
            return completedDays
        }
        return min(completedDays, timesPerWeek)
    }

    public var completedRepetitionsThisWeek: Int {
        let completedRepetitions = Dictionary(grouping: completions) { calendar.startOfDay(for: $0.day) }
            .values
            .reduce(0) { $0 + min($1.count, repetitionsPerDay) }

        guard case .weeklyCount(let timesPerWeek) = habit.schedule.frequency else {
            return completedRepetitions
        }
        return min(completedRepetitions, max(timesPerWeek, 1) * repetitionsPerDay)
    }

    private var repetitionsPerDay: Int {
        max(habit.schedule.repetitionsPerDay, 1)
    }
}
