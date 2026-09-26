//
//  ReminderCandidate.swift
//  Core
//

import Foundation

/// Un hábito junto con lo único que hace falta saber de hoy para planificar sus recordatorios.
public struct ReminderCandidate: Sendable, Equatable {
    public let habit: Habit
    public let isCompletedToday: Bool

    public init(habit: Habit, isCompletedToday: Bool) {
        self.habit = habit
        self.isCompletedToday = isCompletedToday
    }
}
