import Testing
import Foundation
@testable import Core

private struct Input: Sendable {
    var name = "Leer"
    var color = "#007AFF"
    var icon = "drop"
    var frequency = HabitFrequency.daily
    var repetitionsPerDay = 1
    var isReminderEnabled = true
    var reminderTime = Date(timeIntervalSince1970: 2_000)
    var isMutedOnWeekends = false
}

struct UpdateHabitUseCaseTests {
    private let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private func makeUseCase(
        repository: FakeHabitRepository,
        notificationScheduler: FakeHabitNotificationScheduler = FakeHabitNotificationScheduler()
    ) -> DefaultUpdateHabitUseCase {
        DefaultUpdateHabitUseCase(repository: repository, notificationScheduler: notificationScheduler)
    }

    private func execute(
        _ input: Input,
        id: Habit.ID? = nil,
        isActive: Bool = true,
        with useCase: DefaultUpdateHabitUseCase
    ) async throws {
        try await useCase.execute(
            id: id ?? fixedID,
            isActive: isActive,
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
    func updatesTheHabitWithTheGivenID(frequency: HabitFrequency) async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        try await execute(
            Input(name: "Beber agua", frequency: frequency, repetitionsPerDay: 2),
            with: useCase
        )

        #expect(await repository.updateCalls == [
            UpdateCall(
                id: fixedID,
                name: "Beber agua",
                color: "#007AFF",
                icon: "drop",
                schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: 2),
                reminder: HabitReminder(
                    time: Date(timeIntervalSince1970: 2_000),
                    isEnabled: true,
                    isMutedOnWeekends: false
                )
            )
        ])
    }

    @Test func trimsTheName() async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        try await execute(Input(name: "  Leer \n"), with: useCase)

        #expect(await repository.updateCalls.first?.name == "Leer")
    }

    // MARK: Notificaciones

    @Test func cancelsAndReschedulesRemindersAfterUpdating() async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = makeUseCase(repository: repository, notificationScheduler: scheduler)

        try await execute(Input(), with: useCase)

        #expect(await scheduler.cancelledHabitIDs == [fixedID])
        #expect(await scheduler.scheduledHabits.map(\.id) == [fixedID])
        #expect(await scheduler.scheduledHabits.map(\.reminder) == [
            HabitReminder(time: Date(timeIntervalSince1970: 2_000), isEnabled: true, isMutedOnWeekends: false)
        ])
    }

    /// El scheduler ignora los hábitos pausados; para eso el caso de uso tiene que pasarle el
    /// estado real y no suponer que está activo.
    @Test(arguments: [true, false])
    func schedulesWithTheRealActiveState(isActive: Bool) async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = makeUseCase(repository: repository, notificationScheduler: scheduler)

        try await execute(Input(), isActive: isActive, with: useCase)

        #expect(await scheduler.scheduledHabits.map(\.isActive) == [isActive])
    }

    // MARK: Validación

    @Test(arguments: [
        (Input(name: ""), CreateHabitErrorEnum.emptyName),
        (Input(name: " \n "), CreateHabitErrorEnum.emptyName),
        (Input(color: "blue"), CreateHabitErrorEnum.invalidColor),
        (Input(color: "#12345"), CreateHabitErrorEnum.invalidColor),
        (Input(color: "#GGGGGG"), CreateHabitErrorEnum.invalidColor),
        (Input(color: "007AFF0"), CreateHabitErrorEnum.invalidColor),
        (Input(color: "#ＡＢＣ１２３"), CreateHabitErrorEnum.invalidColor),
        (Input(repetitionsPerDay: 0), CreateHabitErrorEnum.invalidRepetitionsPerDay),
        (Input(frequency: .weeklyCount(timesPerWeek: 0)), CreateHabitErrorEnum.invalidTimesPerWeek),
        (Input(frequency: .weeklyCount(timesPerWeek: 8)), CreateHabitErrorEnum.invalidTimesPerWeek),
        (Input(frequency: .fixedDays(weekdays: [])), CreateHabitErrorEnum.emptyWeekdays),
        (Input(frequency: .fixedDays(weekdays: [0, 2])), CreateHabitErrorEnum.invalidWeekdays),
        (Input(frequency: .fixedDays(weekdays: [2, 8])), CreateHabitErrorEnum.invalidWeekdays),
    ])
    fileprivate func rejectsInvalidInputWithoutTouchingTheRepository(
        input: Input,
        expectedError: CreateHabitErrorEnum
    ) async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = makeUseCase(repository: repository, notificationScheduler: scheduler)

        await #expect(throws: expectedError) {
            try await execute(input, with: useCase)
        }
        #expect(await repository.updateCalls.isEmpty)
        #expect(await scheduler.cancelledHabitIDs.isEmpty)
        #expect(await scheduler.scheduledHabits.isEmpty)
    }

    // MARK: Errores del repositorio

    @Test func propagatesRepositoryErrorsWithoutTouchingNotifications() async {
        let repository = FakeHabitRepository(error: RepositoryFailure())
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = makeUseCase(repository: repository, notificationScheduler: scheduler)

        await #expect(throws: RepositoryFailure()) {
            try await execute(Input(), with: useCase)
        }
        #expect(await scheduler.cancelledHabitIDs.isEmpty)
        #expect(await scheduler.scheduledHabits.isEmpty)
    }
}
