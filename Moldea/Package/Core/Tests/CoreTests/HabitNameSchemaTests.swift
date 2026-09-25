import Testing
import FoundationModels
@testable import Core

struct HabitNameSchemaTests {
    @Test func `Builds a schema from the habit names`() {
        let habits = [makeHabit(name: "Leer"), makeHabit(name: "Correr 5 min")]

        #expect(throws: Never.self) {
            try HabitNameSchema.makeSchema(for: habits)
        }
    }

    @Test func `Builds a schema when two habits share a name`() throws {
        let habits = [makeHabit(name: "Leer"), makeHabit(name: "Leer")]

        #expect(throws: Never.self) {
            try HabitNameSchema.makeSchema(for: habits)
        }
    }

    @Test func `Builds a completion schema from the habit names`() {
        let habits = [makeHabit(name: "Leer"), makeHabit(name: "Leer"), makeHabit(name: "Correr")]

        #expect(throws: Never.self) {
            try HabitNameSchema.makeCompletionSchema(for: habits)
        }
    }

    @Test func `Builds a completion schema when a habit is called like the none option`() {
        let habits = [makeHabit(name: HabitNameSchema.noneOption)]

        #expect(throws: Never.self) {
            try HabitNameSchema.makeCompletionSchema(for: habits)
        }
    }

    // MARK: Deduplicación

    @Test func `Deduplicates names keeping the original order`() {
        let habits = [
            makeHabit(name: "Leer"),
            makeHabit(name: "Correr"),
            makeHabit(name: "Leer"),
            makeHabit(name: "Nadar"),
        ]

        #expect(HabitNameSchema.uniqueNames(of: habits) == ["Leer", "Correr", "Nadar"])
    }

    // MARK: Opciones

    @Test func `Adds the none option after the habit names`() {
        let habits = [makeHabit(name: "Leer"), makeHabit(name: "Correr")]

        #expect(HabitNameSchema.options(for: habits) == ["Leer", "Correr", HabitNameSchema.noneOption])
    }

    @Test func `Does not repeat the none option when a habit already has that name`() {
        let habits = [makeHabit(name: HabitNameSchema.noneOption)]

        #expect(HabitNameSchema.options(for: habits) == [HabitNameSchema.noneOption])
    }

    @Test func `Returns no names for an empty habit list`() {
        #expect(HabitNameSchema.uniqueNames(of: []).isEmpty)
    }
}
