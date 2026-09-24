import Testing
import Foundation
@testable import Core

struct ToggleTodayHabitUseCaseTests {
    private let day = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))

    private final class FakeGetTodayHabits: GetTodayHabitsUseCase, @unchecked Sendable {
        private var results: [[TodayHabit]]

        init(results: [[TodayHabit]]) {
            self.results = results
        }

        func execute(on day: Date) async throws -> [TodayHabit] {
            results.count > 1 ? results.removeFirst() : (results.first ?? [])
        }
    }

    private final class FakeToggle: ToggleHabitCompletionUseCase, @unchecked Sendable {
        private(set) var calls: [SetCompletionsCall] = []

        func execute(
            habitID: Habit.ID,
            day: Date,
            completedCount: Int,
            repetitionsPerDay: Int
        ) async throws {
            calls.append(
                SetCompletionsCall(
                    habitID: habitID,
                    day: day,
                    count: completedCount,
                    completedAt: day
                )
            )
        }
    }

    private final class FakeStore: TodayProgressStore, @unchecked Sendable {
        private(set) var saved: [Double] = []
        func save(fraction: Double, on day: Date) { saved.append(fraction) }
        func fraction(on day: Date) -> Double { 0 }
    }

    private struct FixedProgress: CalculateHabitsProgressUseCaseProtocol {
        let progress: HabitsProgress
        func execute(habits: [TodayHabit], scope: HabitProgressScopeEnum) -> HabitsProgress { progress }
    }

    private func makeTodayHabit(id: UUID, completed: Int, repetitions: Int = 3) -> TodayHabit {
        let habit = makeHabit(id: id, name: "Leer", repetitionsPerDay: repetitions)
        let completions = (0..<completed).map {
            HabitCompletion(id: UUID(), habitID: id, day: day, repetitionIndex: $0, completedAt: day)
        }
        return TodayHabit(habit: habit, completions: completions, referenceDay: day)
    }

    @Test func togglesWithTheCurrentStoredStateAndPublishesTheNewProgress() async throws {
        let id = UUID()
        let toggle = FakeToggle()
        let store = FakeStore()
        let useCase = DefaultToggleTodayHabitUseCase(
            getTodayHabitsUseCase: FakeGetTodayHabits(results: [
                [makeTodayHabit(id: id, completed: 1)],
                [makeTodayHabit(id: id, completed: 2)],
            ]),
            toggleHabitCompletionUseCase: toggle,
            calculateHabitsProgressUseCase: FixedProgress(
                progress: HabitsProgress(completedHabits: 0, totalHabits: 1, completedUnits: 2, totalUnits: 3)
            ),
            todayProgressStore: store
        )

        try await useCase.execute(habitID: id, on: day)

        #expect(toggle.calls.map(\.habitID) == [id])
        #expect(toggle.calls.map(\.count) == [1])
        #expect(store.saved == [2.0 / 3.0])
    }

    @Test func doesNothingWhenTheHabitIsNotScheduledToday() async throws {
        let toggle = FakeToggle()
        let store = FakeStore()
        let useCase = DefaultToggleTodayHabitUseCase(
            getTodayHabitsUseCase: FakeGetTodayHabits(results: [[]]),
            toggleHabitCompletionUseCase: toggle,
            calculateHabitsProgressUseCase: FixedProgress(
                progress: HabitsProgress(completedHabits: 0, totalHabits: 0, completedUnits: 0, totalUnits: 0)
            ),
            todayProgressStore: store
        )

        try await useCase.execute(habitID: UUID(), on: day)

        #expect(toggle.calls.isEmpty)
        #expect(store.saved.isEmpty)
    }
}
