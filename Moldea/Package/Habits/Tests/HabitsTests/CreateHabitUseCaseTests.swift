import Testing
import Foundation
import Core
@testable import Habits

private actor FakeHabitRepository: HabitRepository {
    private(set) var created: [Habit] = []
    private let error: (any Error)?

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func create(_ habit: Habit) async throws {
        if let error { throw error }
        created.append(habit)
    }

    func delete(id: Habit.ID) async throws {}

    func setActive(id: Habit.ID, isActive: Bool, updatedAt: Date) async throws {}

    func setReminderEnabled(
        id: Habit.ID,
        isEnabled: Bool,
        defaultTime: Date,
        updatedAt: Date
    ) async throws {}

    func updateReminder(id: Habit.ID, reminder: HabitReminder?, updatedAt: Date) async throws {}

    func update(
        id: Habit.ID,
        name: String,
        color: String,
        icon: String,
        schedule: HabitSchedule,
        reminder: HabitReminder?,
        updatedAt: Date
    ) async throws {}
}

private actor FakeHabitNotificationScheduler: HabitNotificationScheduler {
    private(set) var scheduledHabits: [Habit] = []

    func scheduleReminder(for habit: Habit) async {
        scheduledHabits.append(habit)
    }

    func cancelReminders(for habitID: Habit.ID) async {}
}

private struct RepositoryFailure: Error, Equatable {}

private struct Input: Sendable {
    var name = "Leer"
    var color = "#007AFF"
    var icon = "drop"
    var frequency = HabitFrequency.daily
    var repetitionsPerDay = 1
    var isReminderEnabled = false
    var reminderTime = Date(timeIntervalSince1970: 2_000)
    var isMutedOnWeekends = false
}

struct CreateHabitUseCaseTests {
    private let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let fixedDate = Date(timeIntervalSince1970: 1_000)

    private func makeUseCase(
        repository: FakeHabitRepository,
        notificationScheduler: FakeHabitNotificationScheduler = FakeHabitNotificationScheduler()
    ) -> DefaultCreateHabitUseCase {
        let id = fixedID
        let date = fixedDate
        return DefaultCreateHabitUseCase(
            repository: repository,
            notificationScheduler: notificationScheduler,
            makeID: { id },
            now: { date }
        )
    }

    private func execute(_ input: Input, with useCase: DefaultCreateHabitUseCase) async throws {
        try await useCase.execute(
            name: input.name,
            color: input.color,
            icon: input.icon,
            frequency: input.frequency,
            repetitionsPerDay: input.repetitionsPerDay,
            isReminderEnabled: input.isReminderEnabled,
            reminderTime: input.reminderTime,
            isMutedOnWeekends: input.isMutedOnWeekends
        )
    }

    // MARK: Caso feliz

    @Test(arguments: [
        HabitFrequency.daily,
        .weeklyCount(timesPerWeek: 3),
        .fixedDays(weekdays: [2, 4, 6]),
    ])
    func createsTheHabitWithGeneratedIDAndDates(frequency: HabitFrequency) async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        try await execute(
            Input(name: "Beber agua", frequency: frequency, repetitionsPerDay: 2),
            with: useCase
        )

        let expected = Habit(
            id: fixedID,
            name: "Beber agua",
            color: "#007AFF",
            icon: "drop",
            isActive: true,
            createdAt: fixedDate,
            updatedAt: fixedDate,
            schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: 2),
            reminder: HabitReminder(
                time: Date(timeIntervalSince1970: 2_000),
                isEnabled: false,
                isMutedOnWeekends: false
            )
        )
        #expect(await repository.created == [expected])
    }

    @Test func trimsTheName() async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        try await execute(Input(name: "  Leer \n"), with: useCase)

        #expect(await repository.created.first?.name == "Leer")
    }

    // MARK: Validación

    @Test(arguments: [
        (Input(name: ""), CreateHabitError.emptyName),
        (Input(name: " \n "), CreateHabitError.emptyName),
        (Input(color: "blue"), CreateHabitError.invalidColor),
        (Input(color: "#12345"), CreateHabitError.invalidColor),
        (Input(color: "#GGGGGG"), CreateHabitError.invalidColor),
        (Input(color: "007AFF0"), CreateHabitError.invalidColor),
        (Input(color: "#ＡＢＣ１２３"), CreateHabitError.invalidColor),
        (Input(repetitionsPerDay: 0), CreateHabitError.invalidRepetitionsPerDay),
        (Input(frequency: .weeklyCount(timesPerWeek: 0)), CreateHabitError.invalidTimesPerWeek),
        (Input(frequency: .weeklyCount(timesPerWeek: 8)), CreateHabitError.invalidTimesPerWeek),
        (Input(frequency: .fixedDays(weekdays: [])), CreateHabitError.emptyWeekdays),
        (Input(frequency: .fixedDays(weekdays: [0, 2])), CreateHabitError.invalidWeekdays),
        (Input(frequency: .fixedDays(weekdays: [2, 8])), CreateHabitError.invalidWeekdays),
    ])
    fileprivate func rejectsInvalidInputWithoutTouchingTheRepository(
        input: Input,
        expectedError: CreateHabitError
    ) async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        await #expect(throws: expectedError) {
            try await execute(input, with: useCase)
        }
        #expect(await repository.created.isEmpty)
    }

    // MARK: Errores del repositorio

    @Test func propagatesRepositoryErrors() async {
        let repository = FakeHabitRepository(error: RepositoryFailure())
        let useCase = makeUseCase(repository: repository)

        await #expect(throws: RepositoryFailure()) {
            try await execute(Input(), with: useCase)
        }
    }
}
