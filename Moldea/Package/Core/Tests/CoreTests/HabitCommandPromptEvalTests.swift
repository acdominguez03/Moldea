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

    // MARK: Intención

    @Test(arguments: HabitCommandSamples.all)
    func `Classifies the intent of the phrase`(sample: HabitCommandSample) async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(in: sample.phrase, from: Self.habits, today: Self.today)

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
        ("ya no quiero seguir hidratándome", "Beber agua"),
    ])
    func `Picks the habit the delete phrase refers to`(
        phrase: String,
        expectedName: String
    ) async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(in: phrase, from: Self.habits, today: Self.today)

        let habitID = try #require(
            { if case .delete(let id) = command { return id } else { return nil } }(),
            "\(phrase) no se ha clasificado como delete: \(command)"
        )
        #expect(Self.habits.first { $0.id == habitID }?.name == expectedName)
    }

    @Test(arguments: [
        "borra el hábito de nadar",
        "elimina el hábito de tocar la guitarra",
        "quita el de hacer yoga",
        "borra el hábito de cocinar",
    ])
    func `Throws habit not found when no habit is the activity of the phrase`(phrase: String) async {
        let parser = FoundationModelsHabitCommandParser()

        await #expect(throws: HabitCommandErrorEnum.habitNotFound, "\(phrase)") {
            try await parser.parseCommand(in: phrase, from: Self.habits, today: Self.today)
        }
    }

    private static let otherHabits = [
        makeHabit(name: "Meditar"),
        makeHabit(name: "Estudiar inglés"),
        makeHabit(name: "Andar 3 km"),
        makeHabit(name: "Beber muchas agua"),
        makeHabit(name: "Correr 5 min"),
        makeHabit(name: "Tomar vitaminas"),
    ]

    @Test(arguments: [
        ("borra el hábito de correr", "Correr 5 min"),
        ("elimina el de estudiar", "Estudiar inglés"),
        ("ya no quiero caminar", "Andar 3 km"),
        ("quita lo del agua", "Beber muchas agua"),
        ("borra meditar", "Meditar"),
    ])
    func `Picks the habit the delete phrase refers to in a list unlike the example`(
        phrase: String,
        expectedName: String
    ) async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(in: phrase, from: Self.otherHabits, today: [])

        let habitID = try #require(
            { if case .delete(let id) = command { return id } else { return nil } }(),
            "\(phrase) no se ha clasificado como delete: \(command)"
        )
        #expect(Self.otherHabits.first { $0.id == habitID }?.name == expectedName, "\(phrase)")
    }

    @Test(arguments: [
        "borra el hábito de nadar",
        "elimina el hábito de tocar la guitarra",
        "quita el de hacer yoga",
        "borra el hábito de leer",
        "ya no quiero ir al gimnasio",
    ])
    func `Throws habit not found in a list unlike the example`(phrase: String) async {
        let parser = FoundationModelsHabitCommandParser()

        await #expect(throws: HabitCommandErrorEnum.habitNotFound, "\(phrase)") {
            try await parser.parseCommand(in: phrase, from: Self.otherHabits, today: [])
        }
    }

    @Test func `Throws habit not found when there are no habits to delete`() async {
        let parser = FoundationModelsHabitCommandParser()

        await #expect(throws: HabitCommandErrorEnum.habitNotFound) {
            try await parser.parseCommand(in: "borra el hábito de correr", from: [], today: Self.today)
        }
    }

    // MARK: Completar

    private static func completed(_ todayHabit: TodayHabit) -> TodayHabit {
        let completions = (0..<todayHabit.habit.schedule.repetitionsPerDay).map { index in
            HabitCompletion(
                id: UUID(),
                habitID: todayHabit.habit.id,
                day: todayHabit.referenceDay,
                repetitionIndex: index,
                completedAt: todayHabit.referenceDay
            )
        }
        return TodayHabit(
            habit: todayHabit.habit,
            completions: completions,
            referenceDay: todayHabit.referenceDay
        )
    }

    private static func names(_ ids: [Habit.ID]) -> Set<String> {
        Set(ids.compactMap { id in habits.first { $0.id == id }?.name })
    }

    @Test(arguments: [
        ("hoy he leído", Set(["Leer"])),
        ("he corrido media hora y he bebido agua", Set(["Correr 5 min", "Beber agua"])),
        ("he leído, pero no he corrido", Set(["Leer"])),
        ("hoy me he hidratado bien", Set(["Beber agua"])),
    ])
    func `Picks the habits the phrase says were done`(
        phrase: String,
        expected: Set<String>
    ) async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(in: phrase, from: Self.habits, today: Self.today)

        guard case .complete(let habitIDs) = command else {
            Issue.record("\(phrase) no se ha clasificado como complete: \(command)")
            return
        }
        #expect(Self.names(habitIDs) == expected, "\(phrase)")
    }

    @Test func `Picks a habit that is already completed today too`() async throws {
        let parser = FoundationModelsHabitCommandParser()
        let today = [Self.completed(Self.today[0])] + Self.today.dropFirst()

        let command = try await parser.parseCommand(
            in: "he leído y he corrido",
            from: Self.habits,
            today: today
        )

        guard case .complete(let habitIDs) = command else {
            Issue.record("no se ha clasificado como complete: \(command)")
            return
        }
        #expect(Self.names(habitIDs) == ["Leer", "Correr 5 min"])
    }

    @Test(arguments: ["hoy he nadado", "he ido al gimnasio", "hoy he tocado la guitarra"])
    func `Picks no habit when the phrase mentions none of them`(phrase: String) async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(in: phrase, from: Self.habits, today: Self.today)

        #expect(command == .complete(habitIDs: []), "\(phrase)")
    }

    @Test func `Picks no habit when there are no habits today`() async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(in: "hoy he corrido", from: Self.habits, today: [])

        #expect(command == .complete(habitIDs: []))
    }

    // MARK: Creación

    @Test func `Extracts the name without the amount`() async throws {
        let parser = FoundationModelsHabitCommandParser()

        let command = try await parser.parseCommand(
            in: "quiero crear un hábito de meditar diez minutos",
            from: Self.habits,
            today: Self.today
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

        let command = try await parser.parseCommand(in: phrase, from: Self.habits, today: Self.today)

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
            from: Self.habits,
            today: Self.today
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
            try await parser.parseCommand(in: transcript, from: Self.habits, today: Self.today)
        }
    }
}
