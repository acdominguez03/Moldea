//
//  WeeklyHabitsQuery.swift
//  Core
//
//  Created by Andrés on 23/09/2026.
//

import SwiftUI
import SwiftData

@MainActor
@propertyWrapper
public struct WeeklyHabitsQuery: DynamicProperty {
    @Query(sort: \HabitEntity.name)
    private var habits: [HabitEntity]

    @Query
    private var weekCompletions: [HabitCompletionEntity]

    private let referenceDay: Date

    public init(date: Date = .now) {
        let calendar = Calendar.current
        let week = calendar.dateInterval(of: .weekOfYear, for: date)
        let start = week?.start ?? calendar.startOfDay(for: date)
        let end = week?.end ?? calendar.date(byAdding: .day, value: 7, to: start) ?? start

        referenceDay = calendar.startOfDay(for: date)

        _weekCompletions = Query(filter: #Predicate<HabitCompletionEntity> {
            $0.day >= start && $0.day < end
        })
    }

    public var wrappedValue: [TodayHabit] {
        ScheduledHabitsBuilder.habits(
            from: habits,
            with: weekCompletions,
            referenceDay: referenceDay,
            matching: Self.isWeekly
        )
    }

    static func isWeekly(_ frequency: HabitFrequency) -> Bool {
        if case .weeklyCount = frequency {
            true
        } else {
            false
        }
    }
}
