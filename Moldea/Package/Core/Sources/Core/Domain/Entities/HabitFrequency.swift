//
//  HabitFrequency.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

public enum HabitFrequency: Sendable, Equatable {
    case daily
    case weeklyCount(timesPerWeek: Int)
    case fixedDays(weekdays: Set<Int>)

    public func isScheduled(on weekday: Int) -> Bool {
        switch self {
        case .daily:
            true
        case .fixedDays(let weekdays):
            weekdays.contains(weekday)
        case .weeklyCount:
            false
        }
    }
}
