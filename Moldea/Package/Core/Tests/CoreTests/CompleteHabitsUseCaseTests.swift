import Testing
import Foundation
@testable import Core

struct CompleteHabitsUseCaseTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let referenceDay = Date(timeIntervalSince1970: 1_700_000_000)
    private let completedAt = Date(timeIntervalSince1970: 1_700_003_600)

    private func makeUseCase(
        repository: FakeHabitRepository,
        scheduler: FakeHabitNotificationScheduler = FakeHabitNotificationScheduler()
    ) -> DefaultCompleteHabitsUseCase {
        let completedAt = completedAt
        return DefaultCompleteHabitsUseCase(
            repository: repository,
            notificationScheduler: scheduler,
            calendar: calendar,
            now: { completedAt }
        )
    }

    private func makeTodayHabit(_ habit: Habit, completedToday: Int = 0) -> TodayHabit {
        let day = calendar.startOfDay(for: referenceDay)
        let completions = (0..<completedToday).map { index in
            HabitCompletion(
                id: UUID(),
                habitID: habit.id,
                day: day,
                repetitionIndex: index,
                completedAt: day
            )
        }
        return TodayHabit(habit: habit, completions: completions, referenceDay: day, calendar: calendar)
    }

    @Test func `Adds one repetition to each habit`() async throws {
        let repository = FakeHabitRepository()
        let leer = makeHabit(name: "Leer")
        let agua = makeHabit(name: "Beber agua", repetitionsPerDay: 3)
        let today = [makeTodayHabit(leer), makeTodayHabit(agua, completedToday: 1)]

        let result = try await makeUseCase(repository: repository).execute(habitIDs: [leer.id, agua.id], in: today)

        let day = calendar.startOfDay(for: referenceDay)
        #expect(await repository.setCompletionsCalls == [
            SetCompletionsCall(habitID: leer.id, day: day, count: 1, completedAt: completedAt),
            SetCompletionsCall(habitID: agua.id, day: day, count: 2, completedAt: completedAt),
        ])
        #expect(result == CompleteHabitsResult(completed: [leer.id, agua.id], alreadyCompleted: []))
    }

    @Test func `Reports a habit with every repetition of the day done as already completed`() async throws {
        let repository = FakeHabitRepository()
        let agua = makeHabit(name: "Beber agua", repetitionsPerDay: 2)

        let result = try await makeUseCase(repository: repository).execute(
            habitIDs: [agua.id],
            in: [makeTodayHabit(agua, completedToday: 2)]
        )

        #expect(await repository.setCompletionsCalls.isEmpty)
        #expect(result == CompleteHabitsResult(completed: [], alreadyCompleted: [agua.id]))
    }

    @Test func `Reports a weekly habit that reached its weekly goal as already completed`() async throws {
        let repository = FakeHabitRepository()
        let nadar = makeHabit(name: "Nadar", frequency: .weeklyCount(timesPerWeek: 2))
        let previousDays = [1, 2].map { offset in
            HabitCompletion(
                id: UUID(),
                habitID: nadar.id,
                day: calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: referenceDay))!,
                repetitionIndex: 0,
                completedAt: referenceDay
            )
        }
        let today = TodayHabit(
            habit: nadar,
            completions: previousDays,
            referenceDay: calendar.startOfDay(for: referenceDay),
            calendar: calendar
        )

        let result = try await makeUseCase(repository: repository).execute(habitIDs: [nadar.id], in: [today])

        #expect(await repository.setCompletionsCalls.isEmpty)
        #expect(result == CompleteHabitsResult(completed: [], alreadyCompleted: [nadar.id]))
    }

    @Test func `Marks a weekly habit that has not reached its weekly goal`() async throws {
        let repository = FakeHabitRepository()
        let nadar = makeHabit(name: "Nadar", frequency: .weeklyCount(timesPerWeek: 3))

        let result = try await makeUseCase(repository: repository).execute(
            habitIDs: [nadar.id],
            in: [makeTodayHabit(nadar)]
        )

        #expect(await repository.setCompletionsCalls.map(\.count) == [1])
        #expect(result == CompleteHabitsResult(completed: [nadar.id], alreadyCompleted: []))
    }

    @Test func `Marks a habit mentioned twice only once`() async throws {
        let repository = FakeHabitRepository()
        let leer = makeHabit(name: "Leer")

        let result = try await makeUseCase(repository: repository).execute(
            habitIDs: [leer.id, leer.id],
            in: [makeTodayHabit(leer)]
        )

        #expect(await repository.setCompletionsCalls.count == 1)
        #expect(result == CompleteHabitsResult(completed: [leer.id], alreadyCompleted: []))
    }

    @Test func `Ignores a habit that is not scheduled today`() async throws {
        let repository = FakeHabitRepository()
        let leer = makeHabit(name: "Leer")

        let result = try await makeUseCase(repository: repository).execute(habitIDs: [UUID()], in: [makeTodayHabit(leer)])

        #expect(await repository.setCompletionsCalls.isEmpty)
        #expect(result == CompleteHabitsResult(completed: [], alreadyCompleted: []))
    }

    @Test func `Propagates a repository error`() async {
        let repository = FakeHabitRepository(error: RepositoryFailure())
        let leer = makeHabit(name: "Leer")

        await #expect(throws: RepositoryFailure.self) {
            try await makeUseCase(repository: repository).execute(
                habitIDs: [leer.id],
                in: [makeTodayHabit(leer)]
            )
        }
    }

    // MARK: Notificaciones

    @Test func `Syncs the reminders once when a habit is finished for today`() async throws {
        let scheduler = FakeHabitNotificationScheduler()
        let leer = makeHabit(name: "Leer")
        let agua = makeHabit(name: "Beber agua", repetitionsPerDay: 3)
        let today = [makeTodayHabit(leer), makeTodayHabit(agua, completedToday: 2)]

        _ = try await makeUseCase(repository: FakeHabitRepository(), scheduler: scheduler)
            .execute(habitIDs: [leer.id, agua.id], in: today)

        #expect(await scheduler.syncCallCount == 1)
    }

    @Test func `Does not touch the reminders when no habit reaches its last repetition`() async throws {
        let scheduler = FakeHabitNotificationScheduler()
        let agua = makeHabit(name: "Beber agua", repetitionsPerDay: 3)

        _ = try await makeUseCase(repository: FakeHabitRepository(), scheduler: scheduler)
            .execute(habitIDs: [agua.id], in: [makeTodayHabit(agua, completedToday: 0)])

        #expect(await scheduler.syncCallCount == 0)
    }

    @Test func `Does not touch the reminders when everything was already completed`() async throws {
        let scheduler = FakeHabitNotificationScheduler()
        let agua = makeHabit(name: "Beber agua", repetitionsPerDay: 2)

        _ = try await makeUseCase(repository: FakeHabitRepository(), scheduler: scheduler)
            .execute(habitIDs: [agua.id], in: [makeTodayHabit(agua, completedToday: 2)])

        #expect(await scheduler.syncCallCount == 0)
    }
}
