import Testing
import SwiftData
import Foundation
@testable import Core

@MainActor
struct HabitMapperTests {
    private func makeHabit(frequency: HabitFrequency, repetitionsPerDay: Int = 1) -> Habit {
        Habit(
            id: UUID(),
            name: "Beber agua",
            color: "#007AFF",
            icon: "drop",
            isActive: true,
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 2_000),
            schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: repetitionsPerDay)
        )
    }

    private func makeEntity(schedule: HabitScheduleEntity?) -> HabitEntity {
        let entity = HabitEntity(
            id: UUID(),
            name: "Leer",
            color: "#FF3B30",
            icon: "book",
            active: true,
            createdAt: .now,
            updatedAt: .now
        )
        entity.schedule = schedule
        return entity
    }

    // MARK: Ida y vuelta

    @Test(arguments: [
        HabitFrequency.daily,
        .weeklyCount(timesPerWeek: 3),
        .fixedDays(weekdays: [2, 4, 6]),
    ])
    func roundTripKeepsTheHabit(frequency: HabitFrequency) throws {
        let habit = makeHabit(frequency: frequency, repetitionsPerDay: 3)

        let restored = try HabitMapper.toDomain(HabitMapper.makeEntity(from: habit))

        #expect(restored == habit)
    }

    @Test func fixedWeekdaysArePersistedSorted() {
        let habit = makeHabit(frequency: .fixedDays(weekdays: [6, 2, 4]))

        let entity = HabitMapper.makeEntity(from: habit)

        #expect(entity.schedule?.frequencyType == .fixedDays)
        #expect(entity.schedule?.fixedWeekdays == [2, 4, 6])
    }

    @Test func onlyTheFieldsOfTheFrequencyArePersisted() {
        let daily = HabitMapper.makeEntity(from: makeHabit(frequency: .daily))
        #expect(daily.schedule?.timesPerWeek == nil)
        #expect(daily.schedule?.fixedWeekdays == nil)

        let weekly = HabitMapper.makeEntity(from: makeHabit(frequency: .weeklyCount(timesPerWeek: 4)))
        #expect(weekly.schedule?.timesPerWeek == 4)
        #expect(weekly.schedule?.fixedWeekdays == nil)
    }

    @Test func insertingTheEntityLinksTheInverseRelationship() throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let entity = HabitMapper.makeEntity(from: makeHabit(frequency: .daily))

        context.insert(entity)
        try context.save()

        #expect(entity.schedule?.habit === entity)
    }

    // MARK: Datos incoherentes

    @Test func throwsWhenScheduleIsMissing() {
        let entity = makeEntity(schedule: nil)

        #expect(throws: HabitMappingError.missingSchedule(habitID: entity.id)) {
            try HabitMapper.toDomain(entity)
        }
    }

    @Test func throwsWhenWeeklyCountHasNoTimesPerWeek() {
        let entity = makeEntity(schedule: HabitScheduleEntity(frequencyType: .weeklyCount))

        #expect(throws: HabitMappingError.missingTimesPerWeek(habitID: entity.id)) {
            try HabitMapper.toDomain(entity)
        }
    }

    @Test func throwsWhenFixedDaysHasNoWeekdays() {
        let entity = makeEntity(schedule: HabitScheduleEntity(frequencyType: .fixedDays))

        #expect(throws: HabitMappingError.missingFixedWeekdays(habitID: entity.id)) {
            try HabitMapper.toDomain(entity)
        }
    }
}
