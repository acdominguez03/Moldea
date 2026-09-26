import Testing
import Foundation
import Core
@testable import Settings

private actor FakeHabitRepository: HabitRepository {
    private(set) var updateReminderCalls: [(id: Habit.ID, reminder: HabitReminder?)] = []

    func create(_ habit: Habit) async throws {}

    func delete(id: Habit.ID) async throws {}

    func setActive(id: Habit.ID, isActive: Bool, updatedAt: Date) async throws {}

    func setReminderEnabled(
        id: Habit.ID,
        isEnabled: Bool,
        defaultTime: Date,
        updatedAt: Date
    ) async throws {}

    func updateReminder(id: Habit.ID, reminder: HabitReminder?, updatedAt: Date) async throws {
        updateReminderCalls.append((id: id, reminder: reminder))
    }

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
    private(set) var cancelAllCallCount = 0

    func scheduleReminder(for habit: Habit) async {
        scheduledHabits.append(habit)
    }

    func cancelReminders(for habitID: Habit.ID) async {
        cancelledHabitIDs.append(habitID)
    }

    func cancelAllReminders() async {
        cancelAllCallCount += 1
    }

    func syncReminders() async {}
}

struct UpdateHabitReminderUseCaseTests {
    private func makeHabit() -> Habit {
        Habit(
            id: UUID(),
            name: "Leer",
            color: "#007AFF",
            icon: "book",
            isActive: true,
            createdAt: .now,
            updatedAt: .now,
            schedule: HabitSchedule(frequency: .daily, repetitionsPerDay: 1),
            reminder: HabitReminder(time: Date(timeIntervalSince1970: 1_000), isEnabled: false, isMutedOnWeekends: false)
        )
    }

    @Test func cancelsAndReschedulesRemindersAfterUpdating() async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = DefaultUpdateHabitReminderUseCase(repository: repository, notificationScheduler: scheduler)
        let habit = makeHabit()
        let newTime = Date(timeIntervalSince1970: 5_000)

        try await useCase.execute(habit: habit, isReminderEnabled: true, reminderTime: newTime, isMutedOnWeekends: true)

        let expectedReminder = HabitReminder(time: newTime, isEnabled: true, isMutedOnWeekends: true)
        #expect(await repository.updateReminderCalls.map(\.id) == [habit.id])
        #expect(await repository.updateReminderCalls.map(\.reminder) == [expectedReminder])
        #expect(await scheduler.cancelledHabitIDs == [habit.id])
        #expect(await scheduler.scheduledHabits.map(\.id) == [habit.id])
        #expect(await scheduler.scheduledHabits.map(\.reminder) == [expectedReminder])
    }
}
