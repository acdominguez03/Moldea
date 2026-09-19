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
    /// Hex `#RRGGBB`.
    public let color: String
    /// Nombre del SF Symbol.
    public let icon: String
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date
    public let schedule: HabitSchedule

    public init(
        id: UUID,
        name: String,
        color: String,
        icon: String,
        isActive: Bool,
        createdAt: Date,
        updatedAt: Date,
        schedule: HabitSchedule
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.schedule = schedule
    }
}
