//
//  HabitCompletionEntity.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import SwiftData
import Foundation

@Model
final class HabitCompletionEntity {
    #Index<HabitCompletionEntity>([\.day])

    @Attribute(.unique) var id: UUID
    var habit: HabitEntity?
    var day: Date
    var repetitionIndex: Int
    var completedAt: Date

    init(
        id: UUID,
        habit: HabitEntity? = nil,
        day: Date,
        repetitionIndex: Int,
        completedAt: Date
    ) {
        self.id = id
        self.habit = habit
        self.day = day
        self.repetitionIndex = repetitionIndex
        self.completedAt = completedAt
    }
}
