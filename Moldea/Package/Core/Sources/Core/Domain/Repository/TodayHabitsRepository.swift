//
//  TodayHabitsRepository.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import Foundation

public protocol TodayHabitsRepository: Sendable {
    func fetchTodayHabits(on day: Date) async throws -> [TodayHabit]
}
