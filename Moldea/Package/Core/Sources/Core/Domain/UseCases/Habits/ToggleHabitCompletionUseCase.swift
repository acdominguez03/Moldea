//
//  ToggleHabitCompletionUseCase.swift
//  Core
//
//  Created by Andrés on 23/09/2026.
//

import Foundation

public enum ToggleHabitCompletionModeEnum: Sendable {
    case toggle
    case addOnly
}

public enum ToggleHabitCompletionResultEnum: Sendable, Equatable {
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
        mode: ToggleHabitCompletionModeEnum
    ) async throws -> ToggleHabitCompletionResultEnum
}

extension ToggleHabitCompletionUseCase {
    @discardableResult
    public func execute(
        habitID: Habit.ID,
        day: Date,
        completedCount: Int,
        repetitionsPerDay: Int
    ) async throws -> ToggleHabitCompletionResultEnum {
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
    private let notificationScheduler: any HabitNotificationScheduler
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    public init(
        repository: any HabitRepository,
        notificationScheduler: any HabitNotificationScheduler,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repository = repository
        self.notificationScheduler = notificationScheduler
        self.calendar = calendar
        self.now = now
    }

    @discardableResult
    public func execute(
        habitID: Habit.ID,
        day: Date,
        completedCount: Int,
        repetitionsPerDay: Int,
        mode: ToggleHabitCompletionModeEnum = .toggle
    ) async throws -> ToggleHabitCompletionResultEnum {
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

        // Solo cambia lo que hay que avisar hoy al completar del todo o al deshacer (volver a 0).
        // Un progreso parcial no toca las notificaciones.
        if wasCompleted {
            await notificationScheduler.syncReminders()
            return .reset(total: total)
        }
        if next == total {
            await notificationScheduler.syncReminders()
            return .completed(total: total)
        }
        return .progressed(done: next, total: total)
    }
}
