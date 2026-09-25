//
//  AppDependencies.swift
//  Moldea
//
//  Created by Andrés on 25/09/2026.
//

import Core
import Habits
import Settings
import Statistics
import SwiftData
import Today

struct AppDependencies {
    let core: CoreDependencies
    let habits: HabitsDependencies
    let today: TodayDependencies
    let statistics: StatisticsDependencies
    let settings: SettingsDependencies

    static func live(container: ModelContainer) -> Self {
        let core = CoreDependencies.live(container: container)
        return AppDependencies(
            core: core,
            habits: HabitsDependencies(core: core),
            today: TodayDependencies(core: core),
            statistics: StatisticsDependencies(core: core),
            settings: SettingsDependencies(core: core)
        )
    }
}
