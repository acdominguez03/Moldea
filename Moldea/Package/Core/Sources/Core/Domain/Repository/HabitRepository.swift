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
    func setReminderEnabled(
        id: Habit.ID,
        isEnabled: Bool,
        defaultTime: Date,
        updatedAt: Date
    ) async throws
    func updateReminder(id: Habit.ID, reminder: HabitReminder?, updatedAt: Date) async throws
    
    func setCompletions(
        habitID: Habit.ID,
        day: Date,
        count: Int,
        completedAt: Date
    ) async throws
    func update(
        id: Habit.ID,
        name: String,
        color: String,
        icon: String,
        schedule: HabitSchedule,
        reminder: HabitReminder?,
        updatedAt: Date
    ) async throws
}
