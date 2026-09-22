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

    public func setActive(id: Habit.ID, isActive: Bool, updatedAt: Date) async throws {
        var descriptor = FetchDescriptor<HabitEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            return
        }

        entity.active = isActive
        entity.updatedAt = updatedAt

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func update(
        id: Habit.ID,
        name: String,
        color: String,
        icon: String,
        schedule: HabitSchedule,
        updatedAt: Date
    ) async throws {
        var descriptor = FetchDescriptor<HabitEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            return
        }

        entity.name = name
        entity.color = color
        entity.icon = icon
        entity.updatedAt = updatedAt
        HabitMapper.apply(schedule, to: entity)

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
