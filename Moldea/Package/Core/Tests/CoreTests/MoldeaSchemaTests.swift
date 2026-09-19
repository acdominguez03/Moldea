import Testing
import SwiftData
import Foundation
@testable import Core

@MainActor
struct MoldeaSchemaTests {
    private func makeHabit(name: String, color: String, icon: String) -> HabitEntity {
        HabitEntity(
            id: UUID(),
            name: name,
            color: color,
            icon: icon,
            active: true,
            createdAt: .now,
            updatedAt: .now
        )
    }

    @Test func makesInMemoryContainerWithAllModels() throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)

        let entityNames = Set(container.schema.entities.map(\.name))
        #expect(entityNames == ["HabitEntity", "HabitScheduleEntity", "HabitCompletionEntity"])
    }

    @Test func persistsHabitWithScheduleAndCompletions() throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let habit = makeHabit(name: "Beber agua", color: "#007AFF", icon: "drop")
        habit.schedule = HabitScheduleEntity(
            frequencyType: .fixedDays,
            fixedWeekdays: [2, 4, 6],
            repetitionsPerDay: 3
        )
        context.insert(habit)
        context.insert(
            HabitCompletionEntity(id: UUID(), habit: habit, day: .now, repetitionIndex: 0, completedAt: .now)
        )
        try context.save()

        let habits = try context.fetch(FetchDescriptor<HabitEntity>())
        #expect(habits.count == 1)
        #expect(habits.first?.schedule?.fixedWeekdays == [2, 4, 6])
        #expect(habits.first?.schedule?.habit === habits.first)
        #expect(habits.first?.completions?.count == 1)
    }

    @Test func deletingHabitCascadesToScheduleAndCompletions() throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let habit = makeHabit(name: "Leer", color: "#FF3B30", icon: "book")
        habit.schedule = HabitScheduleEntity(frequencyType: .daily)
        context.insert(habit)
        context.insert(
            HabitCompletionEntity(id: UUID(), habit: habit, day: .now, repetitionIndex: 0, completedAt: .now)
        )
        try context.save()

        context.delete(habit)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<HabitScheduleEntity>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<HabitCompletionEntity>()).isEmpty)
    }
}
