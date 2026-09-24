//
//  GetTodayHabitsUseCase.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import Foundation

public protocol GetTodayHabitsUseCase: Sendable {
    func execute(on day: Date) async throws -> [TodayHabit]
}

public struct DefaultGetTodayHabitsUseCase: GetTodayHabitsUseCase {
    private let repository: any TodayHabitsRepository

    public init(repository: any TodayHabitsRepository) {
        self.repository = repository
    }

    public func execute(on day: Date = .now) async throws -> [TodayHabit] {
        try await repository.fetchTodayHabits(on: day)
    }
}
