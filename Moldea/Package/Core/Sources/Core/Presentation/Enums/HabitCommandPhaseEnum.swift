//
//  HabitCommandPhaseEnum.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

enum HabitCommandPhaseEnum: Equatable {
    case parsing
    case confirmingCreate(NewHabitDraft)
    case confirmingDelete(Habit)
    case recognizing
    case recognized([Habit])
    case done(HabitCommandOutcomeEnum)
    case failed
}
