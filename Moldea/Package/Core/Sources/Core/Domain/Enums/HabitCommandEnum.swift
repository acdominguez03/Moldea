//
//  HabitCommandEnum.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

public enum HabitCommandEnum: Sendable, Equatable {
    case create(NewHabitDraft)
    case delete(habitID: Habit.ID)
    case complete(habitIDs: [Habit.ID])
}
