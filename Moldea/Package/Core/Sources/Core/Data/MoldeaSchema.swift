//
//  MoldeaSchema.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import SwiftData

public enum MoldeaSchema {
    public static var models: [any PersistentModel.Type] {
        [
            HabitEntity.self,
            HabitScheduleEntity.self,
            HabitCompletionEntity.self,
            HabitReminderEntity.self,
        ]
    }

    public static var schema: Schema {
        Schema(models)
    }

    public static func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
