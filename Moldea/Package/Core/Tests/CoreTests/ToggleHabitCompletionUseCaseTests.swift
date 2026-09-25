import Testing
import Foundation
@testable import Core

struct ToggleHabitCompletionUseCaseTests {
    private let habitID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let completedAt = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeUseCase(
        repository: FakeHabitRepository
    ) -> DefaultToggleHabitCompletionUseCase {
        DefaultToggleHabitCompletionUseCase(
            repository: repository,
            calendar: .current,
            now: { self.completedAt }
        )
    }

    @Test func addsOneRepetitionWhenThereIsRoomLeft() async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        try await useCase.execute(
            habitID: habitID,
            day: .now,
            completedCount: 1,
            repetitionsPerDay: 4
        )

        let calls = await repository.setCompletionsCalls
        #expect(calls.map(\.count) == [2])
        #expect(calls.map(\.habitID) == [habitID])
        #expect(calls.map(\.completedAt) == [completedAt])
    }

    @Test func resetsTheCountWhenTheDayIsAlreadyComplete() async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        try await useCase.execute(
            habitID: habitID,
            day: .now,
            completedCount: 4,
            repetitionsPerDay: 4
        )

        #expect(await repository.setCompletionsCalls.map(\.count) == [0])
    }

    @Test func resetsTheCountWhenThereAreMoreCompletionsThanNeeded() async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        try await useCase.execute(
            habitID: habitID,
            day: .now,
            completedCount: 6,
            repetitionsPerDay: 4
        )

        #expect(await repository.setCompletionsCalls.map(\.count) == [0])
    }

    @Test func treatsAnInvalidRepetitionsPerDayAsOne() async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        try await useCase.execute(
            habitID: habitID,
            day: .now,
            completedCount: 0,
            repetitionsPerDay: 0
        )

        #expect(await repository.setCompletionsCalls.map(\.count) == [1])
    }

    @Test func normalizesTheDayToTheStartOfTheDay() async throws {
        let repository = FakeHabitRepository()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        let useCase = DefaultToggleHabitCompletionUseCase(
            repository: repository,
            calendar: calendar,
            now: { self.completedAt }
        )
        let day = Date(timeIntervalSince1970: 1_700_000_000)

        try await useCase.execute(
            habitID: habitID,
            day: day,
            completedCount: 0,
            repetitionsPerDay: 1
        )

        let storedDay = try #require(await repository.setCompletionsCalls.first?.day)
        #expect(storedDay == calendar.startOfDay(for: day))
        #expect(storedDay < day)
    }

    @Test func propagatesRepositoryErrors() async {
        let repository = FakeHabitRepository(error: RepositoryFailure())
        let useCase = makeUseCase(repository: repository)

        await #expect(throws: RepositoryFailure()) {
            try await useCase.execute(
                habitID: habitID,
                day: .now,
                completedCount: 0,
                repetitionsPerDay: 1
            )
        }
    }

    @Test func reportsTheResultOfEachTransition() async throws {
        let useCase = makeUseCase(repository: FakeHabitRepository())

        #expect(try await useCase.execute(habitID: habitID, day: .now, completedCount: 1, repetitionsPerDay: 4) == .progressed(done: 2, total: 4))
        #expect(try await useCase.execute(habitID: habitID, day: .now, completedCount: 3, repetitionsPerDay: 4) == .completed(total: 4))
        #expect(try await useCase.execute(habitID: habitID, day: .now, completedCount: 0, repetitionsPerDay: 1) == .completed(total: 1))
        #expect(try await useCase.execute(habitID: habitID, day: .now, completedCount: 4, repetitionsPerDay: 4) == .reset(total: 4))
    }

    @Test func addOnlyNeverUnchecksAnAlreadyCompleteHabit() async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        let result = try await useCase.execute(
            habitID: habitID,
            day: .now,
            completedCount: 4,
            repetitionsPerDay: 4,
            mode: .addOnly
        )

        #expect(result == .alreadyCompleted(total: 4))
        #expect(await repository.setCompletionsCalls.isEmpty)
    }

    @Test func addOnlyAddsOneRepetitionWhenThereIsRoomLeft() async throws {
        let repository = FakeHabitRepository()
        let useCase = makeUseCase(repository: repository)

        let result = try await useCase.execute(
            habitID: habitID,
            day: .now,
            completedCount: 1,
            repetitionsPerDay: 4,
            mode: .addOnly
        )

        #expect(result == .progressed(done: 2, total: 4))
        #expect(await repository.setCompletionsCalls.map(\.count) == [2])
    }
}
