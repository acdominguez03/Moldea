//
//  Habit.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Foundation

public struct Habit: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let color: String
    public let icon: String
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date
    public let schedule: HabitSchedule
    public let reminder: HabitReminder?

    public init(
        id: UUID,
        name: String,
        color: String,
        icon: String,
        isActive: Bool,
        createdAt: Date,
        updatedAt: Date,
        schedule: HabitSchedule,
        reminder: HabitReminder? = nil
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.schedule = schedule
        self.reminder = reminder
    }
}
