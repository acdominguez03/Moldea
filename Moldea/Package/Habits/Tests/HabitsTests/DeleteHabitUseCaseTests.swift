import Testing
import Foundation
import Core
@testable import Habits

private actor FakeHabitRepository: HabitRepository {
    private(set) var deletedIDs: [Habit.ID] = []
    private let error: (any Error)?

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func create(_ habit: Habit) async throws {}

    func delete(id: Habit.ID) async throws {
        if let error { throw error }
        deletedIDs.append(id)
    }

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
    private(set) var cancelledHabitIDs: [Habit.ID] = []

    func scheduleReminder(for habit: Habit) async {
        scheduledHabits.append(habit)
    }

    func cancelReminders(for habitID: Habit.ID) async {
        cancelledHabitIDs.append(habitID)
    }
}

private struct RepositoryFailure: Error, Equatable {}

struct DeleteHabitUseCaseTests {
    @Test func executeDeletesTheHabitWithTheGivenID() async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = DefaultDeleteHabitUseCase(repository: repository, notificationScheduler: scheduler)
        let id = UUID()

        try await useCase.execute(id: id)

        #expect(await repository.deletedIDs == [id])
    }

    @Test func executeCancelsPendingReminders() async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = DefaultDeleteHabitUseCase(repository: repository, notificationScheduler: scheduler)
        let id = UUID()

        try await useCase.execute(id: id)

        #expect(await scheduler.cancelledHabitIDs == [id])
    }

    @Test func executePropagatesRepositoryErrorsWithoutCancellingReminders() async {
        let repository = FakeHabitRepository(error: RepositoryFailure())
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = DefaultDeleteHabitUseCase(repository: repository, notificationScheduler: scheduler)

        await #expect(throws: RepositoryFailure()) {
            try await useCase.execute(id: UUID())
        }
        #expect(await scheduler.cancelledHabitIDs.isEmpty)
    }
}
