import Testing
import Foundation
@testable import Core

@MainActor
@Suite(.serialized, .enabled(if: PromptEvalSupport.isModelAvailable))
struct HabitCommandPromptEvalTests {
    private static let habits = [
        makeHabit(name: "Leer"),
        makeHabit(name: "Correr 5 min"),
        makeHabit(name: "Beber agua", repetitionsPerDay: 3),
    ]

    private static let today = habits.map {
        TodayHabit(habit: $0, completions: [], referenceDay: .now)
    }

    @Test func `Creates a habit from the draft schema`() async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(
            in: "añade nadar tres veces por semana",
            from: Self.habits,
            today: Self.today
        )

        let draft = try #require(
            { if case .create(let draft) = command { return draft } else { return nil } }(),
            "no se ha clasificado como create: \(command)"
        )
        #expect(draft.frequency == .weeklyCount(timesPerWeek: 3))
    }

    @Test func `Picks the habit to delete from the name schema`() async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(
            in: "borra el hábito de correr",
            from: Self.habits,
            today: Self.today
        )

        let habitID = try #require(
            { if case .delete(let id) = command { return id } else { return nil } }(),
            "no se ha clasificado como delete: \(command)"
        )
        #expect(Self.habits.first { $0.id == habitID }?.name == "Correr 5 min")
    }

    @Test(arguments: ["", "   "])
    func `Rejects an empty transcript without asking the model`(transcript: String) async {
        let parser = FoundationModelsHabitCommandParser()

        await #expect(throws: HabitCommandErrorEnum.notUnderstood) {
            try await parser.parseCommand(in: transcript, from: Self.habits, today: Self.today)
        }
    }
}
