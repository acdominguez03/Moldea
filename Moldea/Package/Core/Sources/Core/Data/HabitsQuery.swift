//
//  HabitsQuery.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import SwiftUI
import SwiftData

@MainActor
@propertyWrapper
public struct HabitsQuery: DynamicProperty {
    @Query(sort: \HabitEntity.createdAt, order: .reverse)
    private var entities: [HabitEntity]

    public init() {}

    public var wrappedValue: [Habit] {
        Self.habits(from: entities)
    }

    static func habits(from entities: [HabitEntity]) -> [Habit] {
        entities.compactMap { entity in
            do {
                return try HabitMapper.toDomain(entity)
            } catch {
                return nil
            }
        }
    }
}
