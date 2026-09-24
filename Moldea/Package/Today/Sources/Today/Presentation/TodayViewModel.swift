//
//  TodayViewModel.swift
//  Today
//
//  Created by Andrés on 23/09/2026.
//

import Observation
import SwiftUI
import WidgetKit
import Core

@Observable
@MainActor
final class TodayViewModel: BaseViewModel {
    private let toggleHabitCompletionUseCase: any ToggleHabitCompletionUseCase
    private let calculateHabitsProgressUseCase: any CalculateHabitsProgressUseCaseProtocol
    private let todayProgressStore: any TodayProgressStore

    private(set) var isLoading: Bool = false
    private(set) var errorMessage: LocalizedStringResource?

    private(set) var selectedTab: TodayTabEnum = .daily

    init(
        toggleHabitCompletionUseCase: any ToggleHabitCompletionUseCase,
        calculateHabitsProgressUseCase: any CalculateHabitsProgressUseCaseProtocol,
        todayProgressStore: any TodayProgressStore
    ) {
        self.toggleHabitCompletionUseCase = toggleHabitCompletionUseCase
        self.calculateHabitsProgressUseCase = calculateHabitsProgressUseCase
        self.todayProgressStore = todayProgressStore
    }

    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func setError(_ message: LocalizedStringResource?) {
        errorMessage = message
    }

    func onToggleCompletion(_ todayHabit: TodayHabit) async {
        await perform {
            try await toggleHabitCompletionUseCase.execute(
                habitID: todayHabit.habit.id,
                day: todayHabit.referenceDay,
                completedCount: todayHabit.completedToday,
                repetitionsPerDay: todayHabit.habit.schedule.repetitionsPerDay
            )
        }
    }
    
    func onTabSelect(newTab: TodayTabEnum) {
        selectedTab = newTab
    }

    func progress(for habits: [TodayHabit]) -> HabitsProgress {
        calculateHabitsProgressUseCase.execute(habits: habits, scope: scope)
    }

    func dailyProgress(for dailyHabits: [TodayHabit]) -> HabitsProgress {
        calculateHabitsProgressUseCase.execute(habits: dailyHabits, scope: .daily)
    }

    func publishDailyProgress(for dailyHabits: [TodayHabit], on day: Date = .now) {
        let progress = dailyProgress(for: dailyHabits)
        todayProgressStore.save(fraction: progress.fraction, on: day)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private var scope: HabitProgressScopeEnum {
        switch selectedTab {
        case .daily:
            .daily
        case .weekly:
            .weekly
        }
    }
}
