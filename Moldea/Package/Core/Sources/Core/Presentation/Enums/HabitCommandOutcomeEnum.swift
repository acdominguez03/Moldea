//
//  HabitCommandOutcomeEnum.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

enum HabitCommandOutcomeEnum: Equatable {
    case created(NewHabitDraft)
    case deleted(Habit)
    case completed(completed: [Habit], alreadyCompleted: [Habit])
}
