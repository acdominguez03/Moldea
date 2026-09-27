//
//  StatisticsDependencies.swift
//  Statistics
//
//  Created by Andrés on 25/09/2026.
//

import Core
import SwiftUI

public struct StatisticsDependencies: Sendable {
    let core: CoreDependencies

    public init(core: CoreDependencies) {
        self.core = core
    }

    public static let preview = StatisticsDependencies(core: .preview)

    @MainActor func makeDayChartViewModel() -> DayChartViewModel {
        DayChartViewModel(calculateHabitProgressUseCase: core.calculateHabitsProgress)
    }

    @MainActor func makeWeekChartViewModel() -> WeekChartViewModel {
        WeekChartViewModel(calculateHabitProgressUseCase: core.calculateHabitsProgress)
    }

    @MainActor func makeMonthChartViewModel() -> MonthChartViewModel {
        MonthChartViewModel(calculateHabitProgressUseCase: core.calculateHabitsProgress)
    }

    @MainActor func makeYearChartViewModel() -> YearChartViewModel {
        YearChartViewModel(calculateHabitProgressUseCase: core.calculateHabitsProgress)
    }
}

extension EnvironmentValues {
    @Entry public var statisticsDependencies: StatisticsDependencies? = nil
}
