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

    @Test func `Returns no names for an empty habit list`() {
        #expect(HabitNameSchema.uniqueNames(of: []).isEmpty)
    }
}
