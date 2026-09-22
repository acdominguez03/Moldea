//
//  HabitRepository.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Foundation

public protocol HabitRepository: Sendable {
    func create(_ habit: Habit) async throws
    func delete(id: Habit.ID) async throws
    func setActive(id: Habit.ID, isActive: Bool, updatedAt: Date) async throws
    func update(
        id: Habit.ID,
        name: String,
        color: String,
        icon: String,
        schedule: HabitSchedule,
        updatedAt: Date
    ) async throws
}
