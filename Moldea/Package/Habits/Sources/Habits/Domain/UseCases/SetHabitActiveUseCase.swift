//
//  SetHabitActiveUseCase.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Foundation
import Core

protocol SetHabitActiveUseCase: Sendable {
    func execute(id: Habit.ID, isActive: Bool) async throws
}

struct DefaultSetHabitActiveUseCase: SetHabitActiveUseCase {
    private let repository: any HabitRepository

    init(repository: any HabitRepository) {
        self.repository = repository
    }

    func execute(id: Habit.ID, isActive: Bool) async throws {
        try await repository.setActive(id: id, isActive: isActive, updatedAt: .now)
    }
}
