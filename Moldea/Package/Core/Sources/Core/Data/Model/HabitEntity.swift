//
//  HabitEntity.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import SwiftData
import Foundation

@Model
final class HabitEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String
    var icon: String
    var active: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \HabitScheduleEntity.habit)
    var schedule: HabitScheduleEntity?

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletionEntity.habit)
    var completions: [HabitCompletionEntity]? = []

    @Relationship(deleteRule: .cascade, inverse: \HabitReminderEntity.habit)
    var reminder: HabitReminderEntity?

    init(
        id: UUID,
        name: String,
        color: String,
        icon: String,
        active: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.active = active
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
