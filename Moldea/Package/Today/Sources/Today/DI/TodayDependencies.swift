//
//  TodayDependencies.swift
//  Today
//
//  Created by Andrés on 25/09/2026.
//

import Core
import SwiftUI

public struct TodayDependencies: Sendable {
    let core: CoreDependencies

    public init(core: CoreDependencies) {
        self.core = core
    }

    public static let preview = TodayDependencies(core: .preview)

    @MainActor func makeTodayViewModel() -> TodayViewModel {
        TodayViewModel(
            toggleHabitCompletionUseCase: core.toggleHabitCompletion,
            calculateHabitsProgressUseCase: core.calculateHabitsProgress,
            todayProgressStore: core.todayProgressStore
        )
    }
}

extension EnvironmentValues {
    @Entry public var todayDependencies: TodayDependencies? = nil
}
