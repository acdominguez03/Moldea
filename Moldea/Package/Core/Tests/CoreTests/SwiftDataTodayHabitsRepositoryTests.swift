import Testing
import SwiftData
import Foundation
@testable import Core

struct SwiftDataTodayHabitsRepositoryTests {
    private let calendar = Calendar.current
    private let day = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))

    @Test func returnsOnlyTheHabitsScheduledForTheDayWithTheirCompletions() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let habitRepository = SwiftDataHabitRepository(modelContainer: container)
        let weekday = calendar.component(.weekday, from: day)
        let otherWeekday = weekday % 7 + 1

        let daily = makeHabit(name: "Beber agua", repetitionsPerDay: 2)
        let today = makeHabit(name: "Gimnasio", frequency: .fixedDays(weekdays: [weekday]))
        let otherDay = makeHabit(name: "Yoga", frequency: .fixedDays(weekdays: [otherWeekday]))
        let weekly = makeHabit(name: "Correr", frequency: .weeklyCount(timesPerWeek: 3))
        for habit in [daily, today, otherDay, weekly] {
            try await habitRepository.create(habit)
        }
        try await habitRepository.setCompletions(
            habitID: daily.id,
            day: day,
            count: 1,
            completedAt: day
        )

        let repository = SwiftDataTodayHabitsRepository(modelContainer: container)
        let habits = try await repository.fetchTodayHabits(on: day)

        #expect(habits.map(\.habit.name) == ["Beber agua", "Gimnasio"])
        #expect(habits.first?.completedToday == 1)
        #expect(habits.last?.completedToday == 0)
    }

    @Test func returnsNothingWhenThereAreNoHabits() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataTodayHabitsRepository(modelContainer: container)

        #expect(try await repository.fetchTodayHabits(on: day).isEmpty)
    }
}
