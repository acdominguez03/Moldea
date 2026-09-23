import Testing
import Foundation
@testable import Core

/// Parámetros de `execute`, con valores válidos por defecto para que cada caso cambie solo lo que prueba.
struct CreateHabitInput: Sendable {
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

    private func execute(
        _ input: CreateHabitInput,
        with useCase: DefaultCreateHabitUseCase
    ) async throws {
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
    func `Creates the habit with the generated id and dates`(
        frequency: HabitFrequency
    ) async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        try await execute(
            CreateHabitInput(name: "Beber agua", frequency: frequency, repetitionsPerDay: 2),
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

    @Test func `Trims the name`() async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        try await execute(CreateHabitInput(name: "  Leer \n"), with: useCase)

        #expect(await repository.created.first?.name == "Leer")
    }

    @Test func `Creates the habit without reminder when using the short form`() async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        try await useCase.execute(
            name: "Leer",
            color: "#007AFF",
            icon: "drop",
            frequency: .daily,
            repetitionsPerDay: 1
        )

        #expect(await repository.created.first?.reminder?.isEnabled == false)
    }

    @Test func `Schedules the reminder of the created habit`() async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = makeUseCase(repository: repository, notificationScheduler: scheduler)

        try await execute(CreateHabitInput(isReminderEnabled: true), with: useCase)

        #expect(await scheduler.scheduledHabits == repository.created)
    }

    // MARK: Validación

    @Test(arguments: [
        (CreateHabitInput(name: ""), CreateHabitErrorEnum.emptyName),
        (CreateHabitInput(name: " \n "), CreateHabitErrorEnum.emptyName),
        (CreateHabitInput(color: "blue"), CreateHabitErrorEnum.invalidColor),
        (CreateHabitInput(color: "#12345"), CreateHabitErrorEnum.invalidColor),
        (CreateHabitInput(color: "#GGGGGG"), CreateHabitErrorEnum.invalidColor),
        (CreateHabitInput(color: "007AFF0"), CreateHabitErrorEnum.invalidColor),
        // Dígitos hexadecimales de ancho completo: `isHexDigit` los acepta, pero no son ASCII.
        (CreateHabitInput(color: "#ＡＢＣ１２３"), CreateHabitErrorEnum.invalidColor),
        (CreateHabitInput(repetitionsPerDay: 0), CreateHabitErrorEnum.invalidRepetitionsPerDay),
        (CreateHabitInput(frequency: .weeklyCount(timesPerWeek: 0)), CreateHabitErrorEnum.invalidTimesPerWeek),
        (CreateHabitInput(frequency: .weeklyCount(timesPerWeek: 8)), CreateHabitErrorEnum.invalidTimesPerWeek),
        (CreateHabitInput(frequency: .fixedDays(weekdays: [])), CreateHabitErrorEnum.emptyWeekdays),
        (CreateHabitInput(frequency: .fixedDays(weekdays: [0, 2])), CreateHabitErrorEnum.invalidWeekdays),
        (CreateHabitInput(frequency: .fixedDays(weekdays: [2, 8])), CreateHabitErrorEnum.invalidWeekdays),
    ])
    func `Rejects invalid input without touching the repository`(
        input: CreateHabitInput,
        expectedError: CreateHabitErrorEnum
    ) async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        await #expect(throws: expectedError) {
            try await execute(input, with: useCase)
        }
        #expect(await repository.created.isEmpty)
    }

    // MARK: Errores del repositorio

    @Test func `Propagates repository errors`() async {
        let repository = FakeHabitRepository(error: RepositoryFailure())
        let useCase = makeUseCase(repository: repository)

        await #expect(throws: RepositoryFailure()) {
            try await execute(CreateHabitInput(), with: useCase)
        }
    }
}
