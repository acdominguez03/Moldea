import Foundation
@testable import Core

struct UpdateCall: Sendable, Equatable {
    let id: Habit.ID
    let name: String
    let color: String
    let icon: String
    let schedule: HabitSchedule
    let reminder: HabitReminder?
}

actor FakeHabitRepository: HabitRepository {
    private(set) var created: [Habit] = []
    private(set) var deleted: [Habit.ID] = []
    private(set) var setActiveCalls: [(id: Habit.ID, isActive: Bool)] = []
    private(set) var updateCalls: [UpdateCall] = []
    private let error: (any Error)?

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func create(_ habit: Habit) async throws {
        if let error { throw error }
        created.append(habit)
    }

    func delete(id: Habit.ID) async throws {
        if let error { throw error }
        deleted.append(id)
    }

    func setActive(id: Habit.ID, isActive: Bool, updatedAt: Date) async throws {
        if let error { throw error }
        setActiveCalls.append((id: id, isActive: isActive))
    }

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
    ) async throws {
        if let error { throw error }
        updateCalls.append(
            UpdateCall(id: id, name: name, color: color, icon: icon, schedule: schedule, reminder: reminder)
        )
    }
}

actor FakeHabitNotificationScheduler: HabitNotificationScheduler {
    private(set) var scheduledHabits: [Habit] = []
    private(set) var cancelledHabitIDs: [Habit.ID] = []

    func scheduleReminder(for habit: Habit) async {
        scheduledHabits.append(habit)
    }

    func cancelReminders(for habitID: Habit.ID) async {
        cancelledHabitIDs.append(habitID)
    }
}

struct RepositoryFailure: Error, Equatable {}

func makeHabit(
    id: UUID = UUID(),
    name: String,
    frequency: HabitFrequency = .daily,
    repetitionsPerDay: Int = 1
) -> Habit {
    Habit(
        id: id,
        name: name,
        color: HabitAppearanceDefaultsEnum.colorHex,
        icon: HabitAppearanceDefaultsEnum.icon,
        isActive: true,
        createdAt: Date(timeIntervalSince1970: 1_000),
        updatedAt: Date(timeIntervalSince1970: 1_000),
        schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: repetitionsPerDay)
    )
}
