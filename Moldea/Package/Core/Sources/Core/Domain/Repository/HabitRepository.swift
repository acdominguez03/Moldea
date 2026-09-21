//
//  HabitRepository.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

public protocol HabitRepository: Sendable {
    func create(_ habit: Habit) async throws
    func delete(id: Habit.ID) async throws
}
