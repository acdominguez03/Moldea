import Testing
import Foundation
import Core
@testable import Today

struct ToggleCall: Sendable, Equatable {
    let habitID: Habit.ID
    let day: Date
    let completedCount: Int
    let repetitionsPerDay: Int
}

actor FakeToggleHabitCompletionUseCase: ToggleHabitCompletionUseCase {
    private(set) var calls: [ToggleCall] = []
    private let error: (any Error)?

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func execute(
        habitID: Habit.ID,
        day: Date,
        completedCount: Int,
        repetitionsPerDay: Int
    ) async throws {
        if let error { throw error }
        calls.append(
            ToggleCall(
                habitID: habitID,
                day: day,
                completedCount: completedCount,
                repetitionsPerDay: repetitionsPerDay
            )
        )
    }
}

final class FakeCalculateHabitsProgressUseCase: CalculateHabitsProgressUseCaseProtocol, @unchecked Sendable {
    private(set) var receivedScopes: [HabitProgressScopeEnum] = []
    private let progress: HabitsProgress

    init(progress: HabitsProgress = HabitsProgress(
        completedHabits: 0,
        totalHabits: 0,
        completedUnits: 0,
        totalUnits: 0
    )) {
        self.progress = progress
    }

    func execute(habits: [TodayHabit], scope: HabitProgressScopeEnum) -> HabitsProgress {
        receivedScopes.append(scope)
        return progress
    }
}

final class FakeTodayProgressStore: TodayProgressStore, @unchecked Sendable {
    private(set) var saved: [(fraction: Double, day: Date)] = []

    func save(fraction: Double, on day: Date) {
        saved.append((fraction, day))
    }

    func fraction(on day: Date) -> Double { 0 }
}

struct UseCaseFailure: Error, Equatable {}

@MainActor
struct TodayViewModelTests {
    private let referenceDay = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))

    private func makeTodayHabit(repetitionsPerDay: Int, completedToday: Int) -> TodayHabit {
        let habit = Habit(
            id: UUID(),
            name: "Beber agua",
            color: "#007AFF",
            icon: "drop",
            isActive: true,
            createdAt: .now,
            updatedAt: .now,
            schedule: HabitSchedule(frequency: .daily, repetitionsPerDay: repetitionsPerDay)
        )
        let completions = (0..<completedToday).map { repetitionIndex in
            HabitCompletion(
                id: UUID(),
                habitID: habit.id,
                day: referenceDay,
                repetitionIndex: repetitionIndex,
                completedAt: referenceDay
            )
        }

        return TodayHabit(habit: habit, completions: completions, referenceDay: referenceDay)
    }

    private func makeViewModel(
        toggleHabitCompletionUseCase: any ToggleHabitCompletionUseCase,
        calculateHabitsProgressUseCase: any CalculateHabitsProgressUseCaseProtocol
            = FakeCalculateHabitsProgressUseCase(),
        todayProgressStore: any TodayProgressStore = FakeTodayProgressStore()
    ) -> TodayViewModel {
        TodayViewModel(
            toggleHabitCompletionUseCase: toggleHabitCompletionUseCase,
            calculateHabitsProgressUseCase: calculateHabitsProgressUseCase,
            todayProgressStore: todayProgressStore
        )
    }

    @Test func toggleSendsTheHabitDayAndCurrentProgress() async {
        let useCase = FakeToggleHabitCompletionUseCase()
        let viewModel = makeViewModel(toggleHabitCompletionUseCase: useCase)
        let todayHabit = makeTodayHabit(repetitionsPerDay: 4, completedToday: 2)

        await viewModel.onToggleCompletion(todayHabit)

        #expect(await useCase.calls == [
            ToggleCall(
                habitID: todayHabit.habit.id,
                day: referenceDay,
                completedCount: 2,
                repetitionsPerDay: 4
            )
        ])
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test func toggleShowsTheGenericErrorWhenTheUseCaseFails() async {
        let useCase = FakeToggleHabitCompletionUseCase(error: UseCaseFailure())
        let viewModel = makeViewModel(toggleHabitCompletionUseCase: useCase)

        await viewModel.onToggleCompletion(makeTodayHabit(repetitionsPerDay: 1, completedToday: 0))

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test func progressUsesTheDailyScopeOnTheDailyTab() {
        let progressUseCase = FakeCalculateHabitsProgressUseCase(
            progress: HabitsProgress(
                completedHabits: 1,
                totalHabits: 2,
                completedUnits: 3,
                totalUnits: 5
            )
        )
        let viewModel = makeViewModel(
            toggleHabitCompletionUseCase: FakeToggleHabitCompletionUseCase(),
            calculateHabitsProgressUseCase: progressUseCase
        )

        let progress = viewModel.progress(
            for: [makeTodayHabit(repetitionsPerDay: 4, completedToday: 2)]
        )

        #expect(progressUseCase.receivedScopes == [.daily])
        #expect(progress.completedUnits == 3)
        #expect(progress.totalUnits == 5)
    }

    @Test func progressUsesTheWeeklyScopeAfterSelectingTheWeeklyTab() {
        let progressUseCase = FakeCalculateHabitsProgressUseCase()
        let viewModel = makeViewModel(
            toggleHabitCompletionUseCase: FakeToggleHabitCompletionUseCase(),
            calculateHabitsProgressUseCase: progressUseCase
        )

        viewModel.onTabSelect(newTab: .weekly)
        _ = viewModel.progress(for: [])

        #expect(progressUseCase.receivedScopes == [.weekly])
    }

    @Test func publishDailyProgressSavesTheDailyFractionEvenOnTheWeeklyTab() {
        let progressUseCase = FakeCalculateHabitsProgressUseCase(
            progress: HabitsProgress(
                completedHabits: 1,
                totalHabits: 2,
                completedUnits: 1,
                totalUnits: 4
            )
        )
        let store = FakeTodayProgressStore()
        let viewModel = makeViewModel(
            toggleHabitCompletionUseCase: FakeToggleHabitCompletionUseCase(),
            calculateHabitsProgressUseCase: progressUseCase,
            todayProgressStore: store
        )

        viewModel.onTabSelect(newTab: .weekly)
        viewModel.publishDailyProgress(for: [], on: referenceDay)

        #expect(progressUseCase.receivedScopes == [.daily])
        #expect(store.saved.count == 1)
        #expect(store.saved.first?.fraction == 0.25)
        #expect(store.saved.first?.day == referenceDay)
    }
}
