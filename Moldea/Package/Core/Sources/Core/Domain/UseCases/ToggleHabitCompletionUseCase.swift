//
//  ToggleHabitCompletionUseCase.swift
//  Core
//
//  Created by Andrés on 23/09/2026.
//

import Foundation

public enum ToggleHabitCompletionMode: Sendable {
    case toggle
    case addOnly
}

public enum ToggleHabitCompletionResult: Sendable, Equatable {
    case progressed(done: Int, total: Int)
    case completed(total: Int)
    case alreadyCompleted(total: Int)
    case reset(total: Int)
}

public protocol ToggleHabitCompletionUseCase: Sendable {
    @discardableResult
    func execute(
        habitID: Habit.ID,
        day: Date,
        completedCount: Int,
        repetitionsPerDay: Int,
        mode: ToggleHabitCompletionMode
    ) async throws -> ToggleHabitCompletionResult
}

extension ToggleHabitCompletionUseCase {
    @discardableResult
    public func execute(
        habitID: Habit.ID,
        day: Date,
        completedCount: Int,
        repetitionsPerDay: Int
    ) async throws -> ToggleHabitCompletionResult {
        try await execute(
            habitID: habitID,
            day: day,
            completedCount: completedCount,
            repetitionsPerDay: repetitionsPerDay,
            mode: .toggle
        )
    }
}

public struct DefaultToggleHabitCompletionUseCase: ToggleHabitCompletionUseCase {
    private let repository: any HabitRepository
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    public init(
        repository: any HabitRepository,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repository = repository
        self.calendar = calendar
        self.now = now
    }

    @discardableResult
    public func execute(
        habitID: Habit.ID,
        day: Date,
        completedCount: Int,
        repetitionsPerDay: Int,
        mode: ToggleHabitCompletionMode = .toggle
    ) async throws -> ToggleHabitCompletionResult {
        let total = max(repetitionsPerDay, 1)
        let wasCompleted = completedCount >= total

        if wasCompleted && mode == .addOnly {
            return .alreadyCompleted(total: total)
        }

        let next = wasCompleted ? 0 : min(completedCount + 1, total)
        try await repository.setCompletions(
            habitID: habitID,
            day: calendar.startOfDay(for: day),
            count: next,
            completedAt: now()
        )

        if wasCompleted {
            return .reset(total: total)
        }
        return next == total ? .completed(total: total) : .progressed(done: next, total: total)
    }
}
