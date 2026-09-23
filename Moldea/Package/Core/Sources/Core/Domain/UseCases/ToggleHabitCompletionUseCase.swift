//
//  ToggleHabitCompletionUseCase.swift
//  Core
//
//  Created by Andrés on 23/09/2026.
//

import Foundation

public protocol ToggleHabitCompletionUseCase: Sendable {
    func execute(
        habitID: Habit.ID,
        day: Date,
        completedCount: Int,
        repetitionsPerDay: Int
    ) async throws
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

    public func execute(
        habitID: Habit.ID,
        day: Date,
        completedCount: Int,
        repetitionsPerDay: Int
    ) async throws {
        let total = max(repetitionsPerDay, 1)
        let next = completedCount >= total ? 0 : min(completedCount + 1, total)

        try await repository.setCompletions(
            habitID: habitID,
            day: calendar.startOfDay(for: day),
            count: next,
            completedAt: now()
        )
    }
}
