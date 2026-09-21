import Testing
import Foundation
@testable import Core

@MainActor
@Suite(.serialized, .enabled(if: PromptEvalSupport.isModelAvailable))
struct HabitCommandPromptEvalTests {
    private static let habits = [
        makeHabit(name: "Leer"),
        makeHabit(name: "Correr 5 min"),
        makeHabit(name: "Beber agua"),
    ]

    // MARK: Intención

    @Test(arguments: HabitCommandSamples.all)
    func `Classifies the intent of the phrase`(sample: HabitCommandSample) async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(in: sample.phrase, from: Self.habits)

        #expect(
            command.kind == sample.expected,
            "\(sample.phrase) -> \(command.kind), esperado \(sample.expected)"
        )
    }

    // MARK: Borrado

    @Test(arguments: [
        ("borra el hábito de correr", "Correr 5 min"),
        ("ya no quiero leer todos los días", "Leer"),
        ("quita lo del agua", "Beber agua"),
    ])
    func `Picks the habit the delete phrase refers to`(
        phrase: String,
        expectedName: String
    ) async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(in: phrase, from: Self.habits)

        let habitID = try #require(
            { if case .delete(let id) = command { return id } else { return nil } }(),
            "\(phrase) no se ha clasificado como delete: \(command)"
        )
        #expect(Self.habits.first { $0.id == habitID }?.name == expectedName)
    }

    @Test func `Throws habit not found when there are no habits to delete`() async {
        let parser = FoundationModelsHabitCommandParser()

        await #expect(throws: HabitCommandErrorEnum.habitNotFound) {
            try await parser.parseCommand(in: "borra el hábito de correr", from: [])
        }
    }

    // MARK: Creación

    @Test func `Extracts the name without the amount`() async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(
            in: "quiero crear un hábito de meditar diez minutos",
            from: Self.habits
        )

        let draft = try #require(
            { if case .create(let draft) = command { return draft } else { return nil } }(),
            "no se ha clasificado como create: \(command)"
        )
        #expect(!draft.name.contains("10"))
        #expect(!draft.name.lowercased().contains("diez"))
        #expect(draft.repetitionsPerDay >= 1)
    }

    @Test(arguments: [
        ("quiero leer los lunes y los miércoles", Set([2, 4])),
        ("crea el hábito de estirar los sábados y domingos", Set([7, 1])),
        ("añade meditar todos los viernes", Set([6])),
    ])
    func `Extracts the weekdays the phrase names`(
        phrase: String,
        expected: Set<Int>
    ) async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(in: phrase, from: Self.habits)

        let draft = try #require(
            { if case .create(let draft) = command { return draft } else { return nil } }(),
            "\(phrase) no se ha clasificado como create: \(command)"
        )
        #expect(draft.frequency == .fixedDays(weekdays: expected))
    }

    @Test func `Extracts a weekly count`() async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(
            in: "añade nadar tres veces por semana",
            from: Self.habits
        )

        let draft = try #require(
            { if case .create(let draft) = command { return draft } else { return nil } }(),
            "no se ha clasificado como create: \(command)"
        )
        #expect(draft.frequency == .weeklyCount(timesPerWeek: 3))
    }

    // MARK: Frase vacía

    @Test(arguments: ["", "   "])
    func `Rejects an empty transcript without asking the model`(transcript: String) async {
        let parser = FoundationModelsHabitCommandParser()

        await #expect(throws: HabitCommandErrorEnum.notUnderstood) {
            try await parser.parseCommand(in: transcript, from: Self.habits)
        }
    }
}
