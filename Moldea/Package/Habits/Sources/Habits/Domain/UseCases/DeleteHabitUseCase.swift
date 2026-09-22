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
    
    init(repository: any HabitRepository) {
        self.repository = repository
    }
    
    func execute(id: Habit.ID) async throws {
        try await repository.delete(id: id)
    }
}
