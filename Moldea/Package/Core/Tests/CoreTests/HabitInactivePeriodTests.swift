import Testing
import SwiftData
import Foundation
@testable import Core

private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    return calendar
}

private func date(_ day: Int, hour: Int = 12) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour)) ?? .distantPast
}

private func makeHabit(isActive: Bool = true, inactivePeriods: [HabitInactivePeriod] = []) -> Habit {
    Habit(
        id: UUID(),
        name: "Leer",
        color: "#5B6470",
        icon: "book",
        isActive: isActive,
        createdAt: date(1),
        updatedAt: date(1),
        schedule: HabitSchedule(frequency: .daily, repetitionsPerDay: 1),
        inactivePeriods: inactivePeriods
    )
}

struct HabitInactivePeriodTests {
    @Test func deactivationDayIsInactiveAndReactivationDayIsActive() {
        let habit = makeHabit(inactivePeriods: [HabitInactivePeriod(start: date(10), end: date(13))])

        #expect(habit.isActive(on: date(9), calendar: calendar))
        #expect(!habit.isActive(on: date(10, hour: 0), calendar: calendar))
        #expect(!habit.isActive(on: date(12), calendar: calendar))
        #expect(habit.isActive(on: date(13, hour: 0), calendar: calendar))
    }

    @Test func deactivatingAndReactivatingTheSameDayKeepsTheDay() {
        let habit = makeHabit(inactivePeriods: [HabitInactivePeriod(start: date(10, hour: 9), end: date(10, hour: 18))])

        #expect(habit.isActive(on: date(10), calendar: calendar))
    }

    @Test func openPeriodCoversEveryFollowingDay() {
        let habit = makeHabit(isActive: false, inactivePeriods: [HabitInactivePeriod(start: date(10))])

        #expect(habit.isActive(on: date(9), calendar: calendar))
        #expect(!habit.isActive(on: date(10), calendar: calendar))
        #expect(!habit.isActive(on: date(30), calendar: calendar))
    }

    @Test func severalPeriodsAreAllRespected() {
        let habit = makeHabit(inactivePeriods: [
            HabitInactivePeriod(start: date(2), end: date(4)),
            HabitInactivePeriod(start: date(8), end: date(9)),
        ])

        #expect(!habit.isActive(on: date(3), calendar: calendar))
        #expect(habit.isActive(on: date(5), calendar: calendar))
        #expect(!habit.isActive(on: date(8), calendar: calendar))
        #expect(habit.isActive(on: date(9), calendar: calendar))
    }

    @Test func inactiveHabitWithoutPeriodsIsInactiveFromItsLastUpdate() {
        let habit = makeHabit(isActive: false)

        #expect(!habit.isActive(on: date(20), calendar: calendar))
    }

    @Test func activeDaysCountsOnlyActiveDaysOfTheInterval() {
        let habit = makeHabit(inactivePeriods: [HabitInactivePeriod(start: date(10), end: date(13))])
        let week = DateInterval(start: date(7, hour: 0), end: date(14, hour: 0))

        #expect(habit.activeDays(in: week, calendar: calendar) == 4)
    }
}

struct SetActiveInactivePeriodsTests {
    @Test func deactivatingOpensAPeriodOnlyOnce() {
        let opened = SwiftDataHabitRepository.inactivePeriods([], settingActive: false, at: date(10))
        let again = SwiftDataHabitRepository.inactivePeriods(opened, settingActive: false, at: date(11))

        #expect(opened == [HabitInactivePeriod(start: date(10))])
        #expect(again == opened)
    }

    @Test func activatingClosesTheOpenPeriod() {
        let closed = SwiftDataHabitRepository.inactivePeriods(
            [HabitInactivePeriod(start: date(2), end: date(4)), HabitInactivePeriod(start: date(10))],
            settingActive: true,
            at: date(12)
        )

        #expect(closed == [
            HabitInactivePeriod(start: date(2), end: date(4)),
            HabitInactivePeriod(start: date(10), end: date(12)),
        ])
    }

    @Test func setActivePersistsThePeriods() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let repository = SwiftDataHabitRepository(modelContainer: container)
        let habit = makeHabit()
        try await repository.create(habit)

        try await repository.setActive(id: habit.id, isActive: false, updatedAt: date(10))
        try await repository.setActive(id: habit.id, isActive: true, updatedAt: date(12))
        try await repository.setActive(id: habit.id, isActive: false, updatedAt: date(20))

        let context = ModelContext(container)
        let stored = try context.fetch(FetchDescriptor<HabitEntity>()).map(HabitMapper.toDomain)
        #expect(stored.first?.inactivePeriods == [
            HabitInactivePeriod(start: date(10), end: date(12)),
            HabitInactivePeriod(start: date(20)),
        ])
    }
}
