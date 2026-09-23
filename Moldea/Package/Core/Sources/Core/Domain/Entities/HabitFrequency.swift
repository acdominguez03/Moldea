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
}
