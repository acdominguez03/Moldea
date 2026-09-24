//
//  ScheduledHabitsBuilder.swift
//  Core
//
//  Created by Andrés on 23/09/2026.
//

import Foundation

enum ScheduledHabitsBuilder {
    static func habits(
        from entities: [HabitEntity],
        with completions: [HabitCompletionEntity],
        referenceDay: Date,
        matching isScheduled: (HabitFrequency) -> Bool
    ) -> [TodayHabit] {
        let completionsByHabit = Dictionary(grouping: completions) {
            $0.habit?.persistentModelID
        }

        return entities.compactMap { entity in
            do {
                let habit = try HabitMapper.toDomain(entity)
                guard isScheduled(habit.schedule.frequency) else {
                    return nil
                }
                let habitCompletions = try (completionsByHabit[entity.persistentModelID] ?? [])
                    .map {
                        try HabitCompletionMapper.toDomain($0)
                    }
                return TodayHabit(
                    habit: habit,
                    completions: habitCompletions,
                    referenceDay: referenceDay
                )
            } catch {
                return nil
            }
        }
    }
}
