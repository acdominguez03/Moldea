import Testing
import Foundation
@testable import Core

struct SetHabitActiveUseCaseTests {
    private let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private func makeHabit(isActive: Bool) -> Habit {
        Habit(
            id: fixedID,
            name: "Leer",
            color: "#007AFF",
            icon: "book",
            isActive: isActive,
            createdAt: .now,
            updatedAt: .now,
            schedule: HabitSchedule(frequency: .daily, repetitionsPerDay: 1),
            reminder: HabitReminder(time: .now, isEnabled: true, isMutedOnWeekends: false)
        )
    }

    @Test func deactivatingCancelsRemindersWithoutScheduling() async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = DefaultSetHabitActiveUseCase(repository: repository, notificationScheduler: scheduler)
        let habit = makeHabit(isActive: true)

        try await useCase.execute(habit: habit)

        #expect(await repository.setActiveCalls.map(\.id) == [habit.id])
        #expect(await repository.setActiveCalls.map(\.isActive) == [false])
        #expect(await scheduler.cancelledHabitIDs == [habit.id])
        #expect(await scheduler.scheduledHabits.isEmpty)
    }

    @Test func reactivatingSchedulesRemindersWithoutCancelling() async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = DefaultSetHabitActiveUseCase(repository: repository, notificationScheduler: scheduler)
        let habit = makeHabit(isActive: false)

        try await useCase.execute(habit: habit)

        #expect(await repository.setActiveCalls.map(\.isActive) == [true])
        #expect(await scheduler.scheduledHabits == [habit])
        #expect(await scheduler.cancelledHabitIDs.isEmpty)
    }

    @Test func propagatesRepositoryErrorsWithoutTouchingNotifications() async {
        let repository = FakeHabitRepository(error: RepositoryFailure())
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = DefaultSetHabitActiveUseCase(repository: repository, notificationScheduler: scheduler)
        let habit = makeHabit(isActive: true)

        await #expect(throws: RepositoryFailure()) {
            try await useCase.execute(habit: habit)
        }
        #expect(await scheduler.scheduledHabits.isEmpty)
        #expect(await scheduler.cancelledHabitIDs.isEmpty)
    }
}
