//
//  MoldeaSchema.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import SwiftData

/// Único punto de verdad del esquema de SwiftData de Moldea.
/// Lo consumen la app y, más adelante, los widgets y los App Intents.
public enum MoldeaSchema {
    public static var models: [any PersistentModel.Type] {
        [
            HabitEntity.self,
            HabitScheduleEntity.self,
            HabitCompletionEntity.self,
        ]
    }

    public static var schema: Schema {
        Schema(models)
    }

    /// - Parameter inMemory: `true` para tests y previews; no toca el disco.
    public static func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
