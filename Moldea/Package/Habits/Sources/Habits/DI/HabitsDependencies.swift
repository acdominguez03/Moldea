//
//  HabitsDependencies.swift
//  Habits
//
//  Created by Andrés on 25/09/2026.
//

import Core
import SwiftUI

public struct HabitsDependencies: Sendable {
    let core: CoreDependencies
    let iconCatalog: any HabitIconCatalog

    public init(core: CoreDependencies) {
        self.init(core: core, iconCatalog: BundleHabitIconCatalog())
    }

    init(core: CoreDependencies, iconCatalog: any HabitIconCatalog) {
        self.core = core
        self.iconCatalog = iconCatalog
    }

    public static let preview = HabitsDependencies(core: .preview)

    @MainActor func makeHabitsViewModel() -> HabitsViewModel {
        HabitsViewModel(
            deleteHabitUseCase: core.deleteHabit,
            setHabitActiveUseCase: core.setHabitActive
        )
    }

    @MainActor func makeHabitFormViewModel(editing habit: Habit? = nil) -> HabitFormViewModel {
        guard let habit else {
            return HabitFormViewModel(
                createHabitUseCase: core.createHabit,
                updateHabitUseCase: core.updateHabit
            )
        }
        return HabitFormViewModel(
            id: habit.id,
            isActive: habit.isActive,
            name: habit.name,
            color: habit.color,
            icon: habit.icon,
            frequency: habit.schedule.frequency,
            repetitionsPerDay: habit.schedule.repetitionsPerDay,
            createHabitUseCase: core.createHabit,
            updateHabitUseCase: core.updateHabit,
            isRemindHabitEnabled: habit.reminder?.isEnabled ?? false,
            isMutedOnWeekends: habit.reminder?.isMutedOnWeekends ?? false,
            reminderTime: habit.reminder?.time ?? HabitFormViewModel.defaultReminderTime()
        )
    }
}

extension EnvironmentValues {
    @Entry public var habitsDependencies = HabitsDependencies.preview
}
