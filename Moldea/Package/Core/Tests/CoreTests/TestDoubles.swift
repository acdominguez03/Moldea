import Foundation
@testable import Core

actor FakeHabitRepository: HabitRepository {
    private(set) var created: [Habit] = []
    private(set) var deleted: [Habit.ID] = []
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
