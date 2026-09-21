//
//  SwiftDataHabitRepository.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import SwiftData
import Foundation

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
    
    public func delete(id: Habit.ID) async throws {
        var descriptor = FetchDescriptor<HabitEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        
        guard let entity = try modelContext.fetch(descriptor).first else {
            return
        }
        
        modelContext.delete(entity)
        
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
