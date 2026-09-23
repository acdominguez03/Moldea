//
//  HabitNameSchema.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

import FoundationModels

enum HabitNameSchema {
    static let habitPropertyKey = "habit"

    static func makeSchema(for habits: [Habit]) throws -> GenerationSchema {
        let root = DynamicGenerationSchema(
            name: "HabitChoice",
            properties: [
                DynamicGenerationSchema.Property(
                    name: habitPropertyKey,
                    description: "El hábito al que se refiere la frase",
                    schema: DynamicGenerationSchema(
                        name: "HabitName",
                        anyOf: uniqueNames(of: habits)
                    )
                )
            ]
        )
        return try GenerationSchema(root: root, dependencies: [])
    }

    static func uniqueNames(of habits: [Habit]) -> [String] {
        var seen = Set<String>()
        return habits.map(\.name).filter { seen.insert($0).inserted }
    }
}
