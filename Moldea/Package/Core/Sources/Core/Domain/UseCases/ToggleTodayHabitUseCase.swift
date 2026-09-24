//
//  ToggleTodayHabitUseCase.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import Foundation

public protocol ToggleTodayHabitUseCase: Sendable {
    func execute(habitID: Habit.ID, on day: Date) async throws
}

public struct DefaultToggleTodayHabitUseCase: ToggleTodayHabitUseCase {
    private let getTodayHabitsUseCase: any GetTodayHabitsUseCase
    private let toggleHabitCompletionUseCase: any ToggleHabitCompletionUseCase
    private let calculateHabitsProgressUseCase: any CalculateHabitsProgressUseCaseProtocol
    private let todayProgressStore: any TodayProgressStore

    public init(
        getTodayHabitsUseCase: any GetTodayHabitsUseCase,
        toggleHabitCompletionUseCase: any ToggleHabitCompletionUseCase,
        calculateHabitsProgressUseCase: any CalculateHabitsProgressUseCaseProtocol,
        todayProgressStore: any TodayProgressStore
    ) {
        self.getTodayHabitsUseCase = getTodayHabitsUseCase
        self.toggleHabitCompletionUseCase = toggleHabitCompletionUseCase
        self.calculateHabitsProgressUseCase = calculateHabitsProgressUseCase
        self.todayProgressStore = todayProgressStore
    }

    public func execute(habitID: Habit.ID, on day: Date) async throws {
        let habits = try await getTodayHabitsUseCase.execute(on: day)
        guard let todayHabit = habits.first(where: { $0.id == habitID }) else {
            return
        }

        try await toggleHabitCompletionUseCase.execute(
            habitID: habitID,
            day: todayHabit.referenceDay,
            completedCount: todayHabit.completedToday,
            repetitionsPerDay: todayHabit.habit.schedule.repetitionsPerDay
        )

        let updatedHabits = try await getTodayHabitsUseCase.execute(on: day)
        let progress = calculateHabitsProgressUseCase.execute(habits: updatedHabits, scope: .daily)
        todayProgressStore.save(fraction: progress.fraction, on: day)
    }
}
