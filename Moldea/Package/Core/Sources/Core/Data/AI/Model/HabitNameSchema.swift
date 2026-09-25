//
//  HabitNameSchema.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

import FoundationModels

enum HabitNameSchema {
    static let reasoningPropertyKey = "reasoning"
    static let activityPropertyKey = "activity"
    static let habitPropertyKey = "habit"
    static let donePropertyKey = "done"
    static let noneOption = "ninguno"

    static func makeSchema(for habits: [Habit]) throws -> GenerationSchema {
        let root = DynamicGenerationSchema(
            name: "HabitChoice",
            properties: [
                DynamicGenerationSchema.Property(
                    name: activityPropertyKey,
                    description: "La actividad que el usuario quiere borrar, con las palabras de la frase",
                    schema: DynamicGenerationSchema(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: habitPropertyKey,
                    description: "El hábito que es exactamente esa actividad, o \(noneOption) si no hay ninguno",
                    schema: DynamicGenerationSchema(
                        name: "HabitName",
                        anyOf: options(for: habits)
                    )
                ),
            ]
        )
        return try GenerationSchema(root: root, dependencies: [])
    }

    static func makeCompletionSchema(for habits: [Habit]) throws -> GenerationSchema {
        let names = uniqueNames(of: habits)
        let root = DynamicGenerationSchema(
            name: "HabitCompletion",
            properties: [
                DynamicGenerationSchema.Property(
                    name: reasoningPropertyKey,
                    description: "Qué actividades dice la frase que ha hecho",
                    schema: DynamicGenerationSchema(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: donePropertyKey,
                    description: "Una entrada por cada actividad hecha que es un hábito de la lista",
                    schema: DynamicGenerationSchema(arrayOf: doneActivity(names))
                ),
            ]
        )
        return try GenerationSchema(root: root, dependencies: [])
    }

    static func options(for habits: [Habit]) -> [String] {
        let names = uniqueNames(of: habits)
        return names.contains(noneOption) ? names : names + [noneOption]
    }

    static func uniqueNames(of habits: [Habit]) -> [String] {
        var seen = Set<String>()
        return habits.map(\.name).filter { seen.insert($0).inserted }
    }

    private static func doneActivity(_ names: [String]) -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "DoneActivity",
            properties: [
                DynamicGenerationSchema.Property(
                    name: activityPropertyKey,
                    description: "La actividad hecha, con las palabras de la frase",
                    schema: DynamicGenerationSchema(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: habitPropertyKey,
                    description: "El hábito que es exactamente esa actividad",
                    schema: DynamicGenerationSchema(name: "HabitName", anyOf: names)
                ),
            ]
        )
    }
}
