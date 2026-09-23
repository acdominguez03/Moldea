//
//  TodayHabitsQuery.swift
//  Core
//
//  Created by Andrés on 23/09/2026.
//

import SwiftUI
import SwiftData

@MainActor
@propertyWrapper
public struct TodayHabitsQuery: DynamicProperty {
    @Query(sort: \HabitEntity.name)
    private var habits: [HabitEntity]

    @Query
    private var todayCompletions: [HabitCompletionEntity]

    private let weekday: Int
    private let referenceDay: Date

    public init(date: Date = .now) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start

        weekday = calendar.component(.weekday, from: date)
        referenceDay = start

        _todayCompletions = Query(filter: #Predicate<HabitCompletionEntity> {
            $0.day >= start && $0.day < end
        })
    }

    public var wrappedValue: [TodayHabit] {
        ScheduledHabitsBuilder.habits(
            from: habits,
            with: todayCompletions,
            referenceDay: referenceDay
        ) { frequency in
            Self.isScheduled(frequency, on: weekday)
        }
    }

    static func isScheduled(_ frequency: HabitFrequency, on weekday: Int) -> Bool {
        switch frequency {
        case .daily:
            true
        case .fixedDays(let weekdays):
            weekdays.contains(weekday)
        case .weeklyCount:
            false
        }
    }
}
