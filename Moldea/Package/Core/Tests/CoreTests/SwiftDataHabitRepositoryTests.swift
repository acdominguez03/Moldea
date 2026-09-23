import Testing
import SwiftData
import Foundation
@testable import Core

struct SwiftDataHabitRepositoryTests {
    private let today = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
    private let completedAt = Date(timeIntervalSince1970: 1_700_003_000)

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

    private func fetchHabits(from container: ModelContainer) throws -> [Habit] {
        let context = ModelContext(container)
        let entities = try context.fetch(FetchDescriptor<HabitEntity>())
        return try entities.map(HabitMapper.toDomain)
    }

    private func fetchCompletions(from container: ModelContainer) throws -> [HabitCompletion] {
        let context = ModelContext(container)
        let entities = try context.fetch(FetchDescriptor<HabitCompletionEntity>())
        return try entities.map(HabitCompletionMapper.toDomain)
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

    @Test func deleteRemovesTheHabit() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let habit = makeHabit(frequency: .daily)
        try await repository.create(habit)

        try await repository.delete(id: habit.id)

        #expect(try fetchHabits(from: container).isEmpty)
    }

    @Test func deleteOnlyRemovesTheGivenHabit() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let first = makeHabit(name: "Leer", frequency: .daily)
        let second = makeHabit(name: "Correr", frequency: .weeklyCount(timesPerWeek: 3))
        try await repository.create(first)
        try await repository.create(second)

        try await repository.delete(id: first.id)

        #expect(try fetchHabits(from: container) == [second])
    }

    @Test func deleteWithUnknownIDDoesNothing() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let habit = makeHabit(frequency: .daily)
        try await repository.create(habit)

        try await repository.delete(id: UUID())

        #expect(try fetchHabits(from: container) == [habit])
    }

    @Test func updateChangesTheEditableFieldsAndKeepsIdentityFields() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let habit = makeHabit(frequency: .daily)
        try await repository.create(habit)
        let newUpdatedAt = Date(timeIntervalSince1970: 3_000)

        try await repository.update(
            id: habit.id,
            name: "Leer más",
            color: "#123ABC",
            icon: "book",
            schedule: HabitSchedule(frequency: .weeklyCount(timesPerWeek: 4), repetitionsPerDay: 1),
            reminder: nil,
            updatedAt: newUpdatedAt
        )

        #expect(try fetchHabits(from: container) == [
            Habit(
                id: habit.id,
                name: "Leer más",
                color: "#123ABC",
                icon: "book",
                isActive: habit.isActive,
                createdAt: habit.createdAt,
                updatedAt: newUpdatedAt,
                schedule: HabitSchedule(frequency: .weeklyCount(timesPerWeek: 4), repetitionsPerDay: 1)
            )
        ])
    }

    @Test func updateChangingFrequencyClearsThePreviousFrequencyFields() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let habit = makeHabit(frequency: .fixedDays(weekdays: [2, 4, 6]))
        try await repository.create(habit)

        try await repository.update(
            id: habit.id,
            name: habit.name,
            color: habit.color,
            icon: habit.icon,
            schedule: HabitSchedule(frequency: .daily, repetitionsPerDay: 1),
            reminder: nil,
            updatedAt: Date(timeIntervalSince1970: 3_000)
        )

        #expect(try fetchHabits(from: container).first?.schedule.frequency == .daily)
    }

    @Test func updateWithUnknownIDDoesNothing() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)

        try await repository.update(
            id: UUID(),
            name: "Leer",
            color: "#007AFF",
            icon: "drop",
            schedule: HabitSchedule(frequency: .daily, repetitionsPerDay: 1),
            reminder: nil,
            updatedAt: .now
        )

        #expect(try fetchHabits(from: container).isEmpty)
    }

    @Test func setCompletionsInsertsOneRowPerRepetition() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let habit = makeHabit(frequency: .daily)
        try await repository.create(habit)

        try await repository.setCompletions(
            habitID: habit.id,
            day: today,
            count: 3,
            completedAt: completedAt
        )

        let stored = try fetchCompletions(from: container)
        #expect(stored.map(\.repetitionIndex).sorted() == [0, 1, 2])
        #expect(stored.allSatisfy { $0.habitID == habit.id })
        #expect(stored.allSatisfy { $0.day == today })
        #expect(stored.allSatisfy { $0.completedAt == completedAt })
    }

    @Test func setCompletionsRemovesTheExtraRepetitions() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let habit = makeHabit(frequency: .daily)
        try await repository.create(habit)
        try await repository.setCompletions(habitID: habit.id, day: today, count: 3, completedAt: completedAt)

        try await repository.setCompletions(habitID: habit.id, day: today, count: 1, completedAt: completedAt)

        #expect(try fetchCompletions(from: container).map(\.repetitionIndex) == [0])
    }

    @Test func setCompletionsWithZeroClearsTheDay() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let habit = makeHabit(frequency: .daily)
        try await repository.create(habit)
        try await repository.setCompletions(habitID: habit.id, day: today, count: 2, completedAt: completedAt)

        try await repository.setCompletions(habitID: habit.id, day: today, count: 0, completedAt: completedAt)

        #expect(try fetchCompletions(from: container).isEmpty)
    }

    @Test func setCompletionsOnlyTouchesTheGivenDay() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let habit = makeHabit(frequency: .daily)
        try await repository.create(habit)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        try await repository.setCompletions(habitID: habit.id, day: yesterday, count: 2, completedAt: completedAt)
        try await repository.setCompletions(habitID: habit.id, day: today, count: 1, completedAt: completedAt)

        try await repository.setCompletions(habitID: habit.id, day: today, count: 0, completedAt: completedAt)

        let stored = try fetchCompletions(from: container)
        #expect(stored.count == 2)
        #expect(stored.allSatisfy { $0.day == yesterday })
    }

    @Test func setCompletionsOnlyTouchesTheGivenHabit() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let first = makeHabit(name: "Leer", frequency: .daily)
        let second = makeHabit(name: "Correr", frequency: .daily)
        try await repository.create(first)
        try await repository.create(second)
        try await repository.setCompletions(habitID: first.id, day: today, count: 1, completedAt: completedAt)

        try await repository.setCompletions(habitID: second.id, day: today, count: 2, completedAt: completedAt)

        let stored = try fetchCompletions(from: container)
        #expect(stored.filter { $0.habitID == first.id }.count == 1)
        #expect(stored.filter { $0.habitID == second.id }.count == 2)
    }

    @Test func setCompletionsWithUnknownIDDoesNothing() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)

        try await repository.setCompletions(
            habitID: UUID(),
            day: today,
            count: 2,
            completedAt: completedAt
        )

        #expect(try fetchCompletions(from: container).isEmpty)
    }
}
