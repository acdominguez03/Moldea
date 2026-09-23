import Testing
import Foundation
@testable import Core

struct GenerableHabitMapperTests {
    private func makeGenerated(
        name: String = "Correr",
        frequency: GenerableFrequencyKind = .daily,
        timesPerWeek: Int = 1,
        weekdays: [GenerableWeekday] = [.monday],
        repetitionsPerDay: Int = 1
    ) -> GenerableHabitDraft {
        GenerableHabitDraft(
            name: name,
            frequency: frequency,
            timesPerWeek: timesPerWeek,
            weekdays: weekdays,
            repetitionsPerDay: repetitionsPerDay
        )
    }

    // MARK: Draft

    @Test(arguments: [
        (GenerableFrequencyKind.daily, 5, [GenerableWeekday.monday, .wednesday], HabitFrequency.daily),
        (.timesPerWeek, 3, [.monday, .wednesday], .weeklyCount(timesPerWeek: 3)),
        (.fixedWeekdays, 5, [.monday, .wednesday, .friday], .fixedDays(weekdays: [2, 4, 6])),
    ])
    func `Maps every frequency kind ignoring the other fields`(
        kind: GenerableFrequencyKind,
        timesPerWeek: Int,
        weekdays: [GenerableWeekday],
        expected: HabitFrequency
    ) throws {
        let draft = try GenerableHabitMapper.draft(
            from: makeGenerated(frequency: kind, timesPerWeek: timesPerWeek, weekdays: weekdays)
        )

        #expect(draft.frequency == expected)
    }

    @Test func `Keeps the name, trimmed, and the repetitions`() throws {
        let draft = try GenerableHabitMapper.draft(
            from: makeGenerated(name: "  Beber agua \n", repetitionsPerDay: 4)
        )

        #expect(draft.name == "Beber agua")
        #expect(draft.repetitionsPerDay == 4)
    }

    @Test func `Deduplicates repeated weekdays`() throws {
        let draft = try GenerableHabitMapper.draft(
            from: makeGenerated(frequency: .fixedWeekdays, weekdays: [.monday, .monday, .wednesday])
        )

        #expect(draft.frequency == .fixedDays(weekdays: [2, 4]))
    }

    @Test(arguments: [
        (GenerableWeekday.sunday, 1),
        (.monday, 2),
        (.tuesday, 3),
        (.wednesday, 4),
        (.thursday, 5),
        (.friday, 6),
        (.saturday, 7),
    ])
    func `Maps each weekday to its Calendar value`(
        weekday: GenerableWeekday,
        expected: Int
    ) throws {
        let draft = try GenerableHabitMapper.draft(
            from: makeGenerated(frequency: .fixedWeekdays, weekdays: [weekday])
        )

        #expect(draft.frequency == .fixedDays(weekdays: [expected]))
    }

    @Test func `Maps monday and wednesday to 2 and 4`() throws {
        let draft = try GenerableHabitMapper.draft(
            from: makeGenerated(frequency: .fixedWeekdays, weekdays: [.monday, .wednesday])
        )

        #expect(draft.frequency == .fixedDays(weekdays: [2, 4]))
    }

    @Test(arguments: ["", "   ", "\n"])
    func `Rejects an empty name`(name: String) {
        #expect(throws: HabitCommandErrorEnum.notUnderstood) {
            try GenerableHabitMapper.draft(from: makeGenerated(name: name))
        }
    }

    @Test(arguments: [0, 8, -1])
    func `Rejects a times per week out of range`(timesPerWeek: Int) {
        #expect(throws: HabitCommandErrorEnum.missingFrequencyData) {
            try GenerableHabitMapper.draft(
                from: makeGenerated(frequency: .timesPerWeek, timesPerWeek: timesPerWeek)
            )
        }
    }

    @Test func `Rejects fixed weekdays with no days`() {
        #expect(throws: HabitCommandErrorEnum.missingFrequencyData) {
            try GenerableHabitMapper.draft(
                from: makeGenerated(frequency: .fixedWeekdays, weekdays: [])
            )
        }
    }

    // MARK: Nombre a identificador

    @Test func `Finds the habit id by name`() throws {
        let correr = makeHabit(name: "Correr 5 min")
        let habits = [makeHabit(name: "Leer"), correr]

        #expect(try GenerableHabitMapper.habitID(forName: "Correr 5 min", in: habits) == correr.id)
    }

    @Test(arguments: ["correr 5 min", "CORRER 5 MIN", "  Correr   5 min  "])
    func `Matches the name ignoring case and spacing`(name: String) throws {
        let correr = makeHabit(name: "Correr 5 min")

        #expect(try GenerableHabitMapper.habitID(forName: name, in: [correr]) == correr.id)
    }

    @Test func `Throws when the name is not on the list`() {
        #expect(throws: HabitCommandErrorEnum.habitNotFound) {
            try GenerableHabitMapper.habitID(forName: "Nadar", in: [makeHabit(name: "Leer")])
        }
    }

    @Test func `Throws when there are no habits`() {
        #expect(throws: HabitCommandErrorEnum.habitNotFound) {
            try GenerableHabitMapper.habitID(forName: "Leer", in: [])
        }
    }

    @Test func `Resolves a duplicated name to the first habit`() throws {
        let first = makeHabit(name: "Leer")
        let second = makeHabit(name: "Leer")

        #expect(try GenerableHabitMapper.habitID(forName: "Leer", in: [first, second]) == first.id)
    }
}
