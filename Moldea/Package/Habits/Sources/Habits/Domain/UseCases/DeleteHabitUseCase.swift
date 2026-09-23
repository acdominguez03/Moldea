//
//  DeleteHabitUseCase.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Core

protocol DeleteHabitUseCase: Sendable {
    func execute(id: Habit.ID) async throws
}

struct DefaultDeleteHabitUseCase: DeleteHabitUseCase {
    private let repository: any HabitRepository
    private let notificationScheduler: any HabitNotificationScheduler

    init(repository: any HabitRepository, notificationScheduler: any HabitNotificationScheduler) {
        self.repository = repository
        self.notificationScheduler = notificationScheduler
    }

    func execute(id: Habit.ID) async throws {
        try await repository.delete(id: id)
        await notificationScheduler.cancelReminders(for: id)
    }
}
