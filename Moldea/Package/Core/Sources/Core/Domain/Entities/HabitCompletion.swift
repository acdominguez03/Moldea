//
//  HabitCompletion.swift
//  Core
//
//  Created by Andrés on 23/09/2026.
//

import Foundation

public struct HabitCompletion: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let habitID: UUID
    public let day: Date
    public let repetitionIndex: Int
    public let completedAt: Date

    public init(
        id: UUID,
        habitID: UUID,
        day: Date,
        repetitionIndex: Int,
        completedAt: Date
    ) {
        self.id = id
        self.habitID = habitID
        self.day = day
        self.repetitionIndex = repetitionIndex
        self.completedAt = completedAt
    }
}
