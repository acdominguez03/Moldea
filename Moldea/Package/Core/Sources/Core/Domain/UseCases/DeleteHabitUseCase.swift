//
//  DeleteHabitUseCase.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

public protocol DeleteHabitUseCase: Sendable {
    func execute(id: Habit.ID) async throws
}

public struct DefaultDeleteHabitUseCase: DeleteHabitUseCase {
    private let repository: any HabitRepository

    public init(repository: any HabitRepository) {
        self.repository = repository
    }

    public func execute(id: Habit.ID) async throws {
        try await repository.delete(id: id)
    }
}
