#if DEBUG
import Testing
import Foundation
import SwiftData
@testable import Core

struct DebugHistorySeederTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }()

    /// 24 de junio de 2026, 12:00 en Madrid.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 12))!
    }

    /// Cada test usa su propia suite para no compartir la marca de "ya sembrado".
    private func makeSuiteName() -> String {
        let name = "DebugHistorySeederTests.\(UUID().uuidString)"
        UserDefaults(suiteName: name)?.removePersistentDomain(forName: name)
        return name
    }

    private func seed(
        into container: ModelContainer,
        suiteName: String
    ) async throws -> Bool {
        try await DebugHistorySeeder(modelContainer: container)
            .seedIfNeeded(userDefaultsSuiteName: suiteName, now: now, calendar: calendar)
    }

    @Test func seedsAtLeastAYearOfHistory() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)

        let didSeed = try await seed(into: container, suiteName: makeSuiteName())

        let context = ModelContext(container)
        let habits = try context.fetch(FetchDescriptor<HabitEntity>())
        let completions = try context.fetch(FetchDescriptor<HabitCompletionEntity>())
        let earliest = try #require(completions.map(\.day).min())
        let yearAgo = try #require(calendar.date(byAdding: .year, value: -1, to: now))

        #expect(didSeed)
        #expect(habits.count == 8)
        #expect(completions.count > 1_500)
        #expect(earliest <= yearAgo)
    }

    @Test func seedsOnlyOnce() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let suiteName = makeSuiteName()

        _ = try await seed(into: container, suiteName: suiteName)
        let countAfterFirst = try ModelContext(container).fetchCount(FetchDescriptor<HabitCompletionEntity>())
        let didSeedAgain = try await seed(into: container, suiteName: suiteName)

        #expect(!didSeedAgain)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<HabitCompletionEntity>()) == countAfterFirst)
    }

    @Test func doesNotTouchAStoreThatAlreadyHasHabits() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        let context = ModelContext(container)
        context.insert(HabitEntity(
            id: UUID(), name: "Mío", color: "#3A6BC6", icon: "drop",
            active: true, createdAt: now, updatedAt: now
        ))
        try context.save()
        let suiteName = makeSuiteName()

        let didSeed = try await seed(into: container, suiteName: suiteName)

        #expect(!didSeed)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<HabitEntity>()) == 1)
        #expect(UserDefaults(suiteName: suiteName)?.bool(forKey: DebugHistorySeeder.seededKey) == false)
    }

    @Test func neverExceedsTheRepetitionsOfADay() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        _ = try await seed(into: container, suiteName: makeSuiteName())

        let habits = try ModelContext(container).fetch(FetchDescriptor<HabitEntity>())
        for habit in habits {
            let perDay = Dictionary(grouping: habit.completions ?? [], by: \.day).mapValues(\.count)
            let limit = try HabitMapper.toDomain(habit).schedule.repetitionsPerDay
            #expect(perDay.values.allSatisfy { $0 <= limit }, "\(habit.name)")
        }
    }

    @Test func aPausedHabitStopsRecordingMonthsAgo() async throws {
        let container = try MoldeaSchema.makeModelContainer(inMemory: true)
        _ = try await seed(into: container, suiteName: makeSuiteName())

        let habits = try ModelContext(container).fetch(FetchDescriptor<HabitEntity>())
        let paused = try #require(habits.first { !$0.active })
        let last = try #require((paused.completions ?? []).map(\.day).max())
        let cutoff = try #require(calendar.date(byAdding: .day, value: -100, to: now))

        #expect(last < cutoff)
    }

    @Test func theHistoryIsReproducible() async throws {
        let first = try MoldeaSchema.makeModelContainer(inMemory: true)
        let second = try MoldeaSchema.makeModelContainer(inMemory: true)

        _ = try await seed(into: first, suiteName: makeSuiteName())
        _ = try await seed(into: second, suiteName: makeSuiteName())

        #expect(
            try ModelContext(first).fetchCount(FetchDescriptor<HabitCompletionEntity>())
                == ModelContext(second).fetchCount(FetchDescriptor<HabitCompletionEntity>())
        )
    }
}
#endif
