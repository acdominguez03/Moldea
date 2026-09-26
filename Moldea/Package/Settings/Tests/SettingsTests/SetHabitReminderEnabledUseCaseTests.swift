import Testing
import Foundation
import Core
@testable import Settings

private actor FakeHabitRepository: HabitRepository {
    private(set) var setReminderEnabledCalls: [(id: Habit.ID, isEnabled: Bool)] = []
    private let error: (any Error)?

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func create(_ habit: Habit) async throws {}

    func delete(id: Habit.ID) async throws {}

    func setActive(id: Habit.ID, isActive: Bool, updatedAt: Date) async throws {}

    func setReminderEnabled(
        id: Habit.ID,
        isEnabled: Bool,
        defaultTime: Date,
        updatedAt: Date
    ) async throws {
        if let error { throw error }
        setReminderEnabledCalls.append((id: id, isEnabled: isEnabled))
    }

    func updateReminder(id: Habit.ID, reminder: HabitReminder?, updatedAt: Date) async throws {}

    func setCompletions(habitID: Habit.ID, day: Date, count: Int, completedAt: Date) async throws {}

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
    private(set) var cancelledHabitIDs: [Habit.ID] = []

    func scheduleReminder(for habit: Habit) async {
        scheduledHabits.append(habit)
    }

    func cancelReminders(for habitID: Habit.ID) async {
        cancelledHabitIDs.append(habitID)
    }

    func cancelAllReminders() async {}

    func syncReminders() async {}
}

private struct RepositoryFailure: Error, Equatable {}

struct SetHabitReminderEnabledUseCaseTests {
    private let defaultTime = Date(timeIntervalSince1970: 8_000)

    private func makeHabit(reminder: HabitReminder?, isActive: Bool = true) -> Habit {
        Habit(
            id: UUID(),
            name: "Leer",
            color: "#007AFF",
            icon: "book",
            isActive: isActive,
            createdAt: .now,
            updatedAt: .now,
            schedule: HabitSchedule(frequency: .daily, repetitionsPerDay: 1),
            reminder: reminder
        )
    }

    private func makeUseCase(
        repository: FakeHabitRepository,
        scheduler: FakeHabitNotificationScheduler
    ) -> DefaultSetHabitReminderEnabledUseCase {
        DefaultSetHabitReminderEnabledUseCase(
            repository: repository,
            notificationScheduler: scheduler,
            defaultReminderTime: { [defaultTime] in defaultTime }
        )
    }

    @Test func disablingCancelsTheHabitsNotificationsAndSchedulesNothing() async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let habit = makeHabit(reminder: HabitReminder(time: .now, isEnabled: true, isMutedOnWeekends: false))

        try await makeUseCase(repository: repository, scheduler: scheduler)
            .execute(habit: habit, isEnabled: false)

        #expect(await repository.setReminderEnabledCalls.map(\.isEnabled) == [false])
        #expect(await scheduler.cancelledHabitIDs == [habit.id])
        #expect(await scheduler.scheduledHabits.isEmpty)
    }

    @Test func enablingKeepsTheExistingTimeAndWeekendPreference() async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let time = Date(timeIntervalSince1970: 3_000)
        let habit = makeHabit(reminder: HabitReminder(time: time, isEnabled: false, isMutedOnWeekends: true))

        try await makeUseCase(repository: repository, scheduler: scheduler)
            .execute(habit: habit, isEnabled: true)

        #expect(await scheduler.cancelledHabitIDs == [habit.id])
        #expect(await scheduler.scheduledHabits.map(\.id) == [habit.id])
        #expect(await scheduler.scheduledHabits.map(\.reminder) == [
            HabitReminder(time: time, isEnabled: true, isMutedOnWeekends: true)
        ])
    }

    @Test func enablingAHabitThatNeverHadAReminderUsesTheDefaultTime() async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let habit = makeHabit(reminder: nil)

        try await makeUseCase(repository: repository, scheduler: scheduler)
            .execute(habit: habit, isEnabled: true)

        #expect(await scheduler.scheduledHabits.map(\.reminder) == [
            HabitReminder(time: defaultTime, isEnabled: true, isMutedOnWeekends: false)
        ])
    }

    @Test func aRepositoryFailureLeavesTheNotificationsUntouched() async {
        let repository = FakeHabitRepository(error: RepositoryFailure())
        let scheduler = FakeHabitNotificationScheduler()
        let habit = makeHabit(reminder: nil)

        await #expect(throws: RepositoryFailure()) {
            try await makeUseCase(repository: repository, scheduler: scheduler)
                .execute(habit: habit, isEnabled: true)
        }
        #expect(await scheduler.cancelledHabitIDs.isEmpty)
        #expect(await scheduler.scheduledHabits.isEmpty)
    }
}
