import Testing
import SwiftData
import Foundation
@testable import Core

struct SwiftDataHabitRepositoryTests {
    private func makeHabit(name: String = "Beber agua", frequency: HabitFrequency) -> Habit {
        Habit(
            id: UUID(),
            name: name,
            color: "#007AFF",
            icon: "drop",
            isActive: true,
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 2_000),
            schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: 2)
        )
    }

    /// Lee lo persistido con un contexto distinto al del repositorio.
    private func fetchHabits(from container: ModelContainer) throws -> [Habit] {
        let context = ModelContext(container)
        let entities = try context.fetch(FetchDescriptor<HabitEntity>())
        return try entities.map(HabitMapper.toDomain)
    }

    @Test(arguments: [
        HabitFrequency.daily,
        .weeklyCount(timesPerWeek: 3),
        .fixedDays(weekdays: [2, 4, 6]),
    ])
    func createPersistsTheHabit(frequency: HabitFrequency) async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let habit = makeHabit(frequency: frequency)

        try await repository.create(habit)

        #expect(try fetchHabits(from: container) == [habit])
    }

    @Test func twoCreatesLeaveTwoHabits() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let first = makeHabit(name: "Leer", frequency: .daily)
        let second = makeHabit(name: "Correr", frequency: .weeklyCount(timesPerWeek: 3))

        try await repository.create(first)
        try await repository.create(second)

        let stored = try fetchHabits(from: container)
        #expect(stored.count == 2)
        #expect(Set(stored.map(\.id)) == [first.id, second.id])
    }
}
