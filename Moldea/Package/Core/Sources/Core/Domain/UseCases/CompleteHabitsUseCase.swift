//
//  CompleteHabitsUseCase.swift
//  Core
//
//  Created by Andrés on 24/09/2026.
//

import Foundation

public protocol CompleteHabitsUseCase: Sendable {
    func execute(habitIDs: [Habit.ID], in todayHabits: [TodayHabit]) async throws -> CompleteHabitsResult
}

public struct DefaultCompleteHabitsUseCase: CompleteHabitsUseCase {
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

    public func execute(habitIDs: [Habit.ID], in todayHabits: [TodayHabit]) async throws -> CompleteHabitsResult {
        var seen = Set<Habit.ID>()
        var completed: [Habit.ID] = []
        var alreadyCompleted: [Habit.ID] = []

        for habitID in habitIDs where seen.insert(habitID).inserted {
            guard let todayHabit = todayHabits.first(where: { $0.id == habitID }) else {
                continue
            }

            guard !Self.isFull(todayHabit) else {
                alreadyCompleted.append(habitID)
                continue
            }

            let total = max(todayHabit.habit.schedule.repetitionsPerDay, 1)

            try await repository.setCompletions(
                habitID: habitID,
                day: calendar.startOfDay(for: todayHabit.referenceDay),
                count: min(todayHabit.completedToday + 1, total),
                completedAt: now()
            )
            completed.append(habitID)
        }

        return CompleteHabitsResult(completed: completed, alreadyCompleted: alreadyCompleted)
    }

    private static func isFull(_ todayHabit: TodayHabit) -> Bool {
        guard !todayHabit.isCompletedToday else { return true }

        guard case .weeklyCount(let timesPerWeek) = todayHabit.habit.schedule.frequency else {
            return false
        }
        return todayHabit.completedDaysThisWeek >= timesPerWeek
    }
}
