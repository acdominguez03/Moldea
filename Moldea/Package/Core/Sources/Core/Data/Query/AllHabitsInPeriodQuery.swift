//
//  AllHabitsInPeriodQuery.swift
//  Core
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI
import SwiftData

@MainActor
@propertyWrapper
public struct AllHabitsInPeriodQuery: DynamicProperty {
    @Query(sort: \HabitEntity.name)
    private var habits: [HabitEntity]

    @Query
    private var periodCompletions: [HabitCompletionEntity]

    private let referenceDay: Date

    public init(_ component: Calendar.Component, date: Date = .now) {
        let calendar = Calendar.current
        let period = calendar.dateInterval(of: component, for: date)
        let start = period?.start ?? calendar.startOfDay(for: date)
        let end = period?.end ?? calendar.date(byAdding: .day, value: 1, to: start) ?? start

        self.init(DateInterval(start: start, end: max(start, end)), date: date)
    }

    public init(_ interval: DateInterval, date: Date = .now) {
        let start = interval.start
        let end = interval.end

        referenceDay = Calendar.current.startOfDay(for: date)

        _periodCompletions = Query(filter: #Predicate<HabitCompletionEntity> {
            $0.day >= start && $0.day < end
        })
    }

    public var wrappedValue: [TodayHabit] {
        ScheduledHabitsBuilder.habits(
            from: habits,
            with: periodCompletions,
            referenceDay: referenceDay,
            matching: { _ in true }
        )
    }
}
