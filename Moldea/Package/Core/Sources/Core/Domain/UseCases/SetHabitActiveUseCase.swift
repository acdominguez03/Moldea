//
//  SetHabitActiveUseCase.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Foundation

public protocol SetHabitActiveUseCase: Sendable {
    func execute(habit: Habit) async throws
}

public struct DefaultSetHabitActiveUseCase: SetHabitActiveUseCase {
    private let repository: any HabitRepository
    private let notificationScheduler: any HabitNotificationScheduler

    public init(repository: any HabitRepository, notificationScheduler: any HabitNotificationScheduler) {
        self.repository = repository
        self.notificationScheduler = notificationScheduler
    }

    public func execute(habit: Habit) async throws {
        let isActive = !habit.isActive
        
        try await repository
            .setActive(id: habit.id, isActive: isActive, updatedAt: .now)

        if isActive {
            print("Hábito activado, guardando reminder")
            await notificationScheduler.scheduleReminder(for: habit)
        } else {
            print("Hábito desactivado, eliminando reminders")
            await notificationScheduler.cancelReminders(for: habit.id)
        }
    }
}
