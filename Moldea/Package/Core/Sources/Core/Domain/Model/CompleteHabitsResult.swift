//
//  CompleteHabitsResult.swift
//  Core
//
//  Created by Andrés on 25/09/2026.
//

public struct CompleteHabitsResult: Sendable, Equatable {
    public let completed: [Habit.ID]
    public let alreadyCompleted: [Habit.ID]

    public init(completed: [Habit.ID], alreadyCompleted: [Habit.ID]) {
        self.completed = completed
        self.alreadyCompleted = alreadyCompleted
    }
}
