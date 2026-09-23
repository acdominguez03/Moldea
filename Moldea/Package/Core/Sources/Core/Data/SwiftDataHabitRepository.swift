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

    public func setReminderEnabled(
        id: Habit.ID,
        isEnabled: Bool,
        defaultTime: Date,
        updatedAt: Date
    ) async throws {
        var descriptor = FetchDescriptor<HabitEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            return
        }

        if let existingReminder = entity.reminder {
            existingReminder.enabled = isEnabled
        } else if isEnabled {
            entity.reminder = HabitReminderEntity(
                time: defaultTime,
                enabled: true,
                isMutedOnWeekends: false
            )
        }
        entity.updatedAt = updatedAt

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func setCompletions(
        habitID: Habit.ID,
        day: Date,
        count: Int,
        completedAt: Date
    ) async throws {
        var descriptor = FetchDescriptor<HabitEntity>(
            predicate: #Predicate { $0.id == habitID }
        )
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            return
        }

        let calendar = Calendar.current
        let existing = (entity.completions ?? [])
            .filter { calendar.isDate($0.day, inSameDayAs: day) }
            .sorted { $0.repetitionIndex < $1.repetitionIndex }

        let target = max(count, 0)
        if target < existing.count {
            for completion in existing[target...] {
                modelContext.delete(completion)
            }
        } else if target > existing.count {
            for repetitionIndex in existing.count..<target {
                modelContext.insert(
                    HabitCompletionEntity(
                        id: UUID(),
                        habit: entity,
                        day: day,
                        repetitionIndex: repetitionIndex,
                        completedAt: completedAt
                    )
                )
            }
        }

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
        reminder: HabitReminder?,
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
        applyReminder(reminder, to: entity)

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    public func updateReminder(
        id: Habit.ID,
        reminder: HabitReminder?,
        updatedAt: Date
    ) async throws {
        var descriptor = FetchDescriptor<HabitEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            return
        }

        entity.updatedAt = updatedAt
        applyReminder(reminder, to: entity)

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    /// Desasignar la relación no borra la fila (el `deleteRule: .cascade` solo actúa al borrar
    /// el `HabitEntity` padre): si el nuevo valor es `nil` y ya había uno, hay que borrarlo
    /// explícitamente del contexto antes de que `HabitMapper.apply` lo desligue.
    private func applyReminder(_ reminder: HabitReminder?, to entity: HabitEntity) {
        if reminder == nil, let orphanedReminder = entity.reminder {
            modelContext.delete(orphanedReminder)
        }
        HabitMapper.apply(reminder, to: entity)
    }
}
