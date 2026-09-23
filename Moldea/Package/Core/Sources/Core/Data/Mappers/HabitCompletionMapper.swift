//
//  HabitCompletionMapper.swift
//  Core
//
//  Created by Andrés on 23/09/2026.
//

import Foundation

enum HabitCompletionMappingError: Error, Equatable {
    case missingHabit(habitCompletionID: UUID)
}

enum HabitCompletionMapper {
    static func toDomain(_ completion: HabitCompletionEntity) throws -> HabitCompletion {
        guard let habit = completion.habit else {
            throw HabitCompletionMappingError.missingHabit(habitCompletionID: completion.id)
        }
        
        return HabitCompletion(
            id: completion.id,
            habitID: habit.id,
            day: completion.day,
            repetitionIndex: completion.repetitionIndex,
            completedAt: completion.completedAt
        )
    }
}
