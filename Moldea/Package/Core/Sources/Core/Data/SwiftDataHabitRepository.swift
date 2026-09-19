//
//  SwiftDataHabitRepository.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import SwiftData

@ModelActor
public actor SwiftDataHabitRepository: HabitRepository {
    public func create(_ habit: Habit) throws {
        modelContext.insert(HabitMapper.makeEntity(from: habit))
        do {
            try modelContext.save()
        } catch {
            // Sin esto, la entidad insertada quedaría pendiente y el siguiente `create` la guardaría.
            modelContext.rollback()
            throw error
        }
    }
}
