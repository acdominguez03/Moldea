import Testing
import Foundation
@testable import Core

struct CalculateHabitsProgressUseCaseTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let referenceDay = Date(timeIntervalSince1970: 1_700_000_000)
    private let useCase = CalculateHabitsProgressUseCase()

    private func makeTodayHabit(
        frequency: HabitFrequency = .daily,
        repetitionsPerDay: Int = 1,
        completedToday: Int = 0,
        completedDays: Int = 0
    ) -> TodayHabit {
        let day = calendar.startOfDay(for: referenceDay)
        let habit = makeHabit(
            name: "Beber agua",
            frequency: frequency,
            repetitionsPerDay: repetitionsPerDay
        )

        func completions(on day: Date, count: Int) -> [HabitCompletion] {
            (0..<count).map { repetitionIndex in
                HabitCompletion(
                    id: UUID(),
                    habitID: habit.id,
                    day: day,
                    repetitionIndex: repetitionIndex,
                    completedAt: day
                )
            }
        }

        let past = (0..<completedDays).flatMap { offset -> [HabitCompletion] in
            let pastDay = calendar.date(byAdding: .day, value: -(offset + 1), to: day) ?? day
            return completions(on: pastDay, count: max(repetitionsPerDay, 1))
        }

        return TodayHabit(
            habit: habit,
            completions: past + completions(on: day, count: completedToday),
            referenceDay: day,
            calendar: calendar
        )
    }

    @Test func dailyProgressWeighsEachRepetition() {
        let progress = useCase.execute(
            habits: [
                makeTodayHabit(repetitionsPerDay: 4, completedToday: 2),
                makeTodayHabit(repetitionsPerDay: 1, completedToday: 1)
            ],
            scope: .daily
        )

        #expect(progress.completedUnits == 3)
        #expect(progress.totalUnits == 5)
        #expect(abs(progress.fraction - 0.6) < 0.000_1)
        #expect(progress.percentage == 60)
    }

    @Test func dailyCompletedHabitsOnlyCountsFinishedOnes() {
        let progress = useCase.execute(
            habits: [
                makeTodayHabit(repetitionsPerDay: 4, completedToday: 2),
                makeTodayHabit(repetitionsPerDay: 1, completedToday: 1)
            ],
            scope: .daily
        )

        #expect(progress.completedHabits == 1)
        #expect(progress.totalHabits == 2)
    }

    @Test func weeklyProgressUsesTimesPerWeek() {
        let progress = useCase.execute(
            habits: [
                makeTodayHabit(frequency: .weeklyCount(timesPerWeek: 3), completedDays: 2),
                makeTodayHabit(frequency: .weeklyCount(timesPerWeek: 2), completedDays: 1)
            ],
            scope: .weekly
        )

        #expect(progress.completedUnits == 3)
        #expect(progress.totalUnits == 5)
        #expect(progress.completedHabits == 0)
        #expect(progress.totalHabits == 2)
    }

    @Test func weeklyProgressCountsTheRepetitionsOfAPartialDay() {
        let progress = useCase.execute(
            habits: [
                makeTodayHabit(
                    frequency: .weeklyCount(timesPerWeek: 3),
                    repetitionsPerDay: 2,
                    completedToday: 1,
                    completedDays: 2
                )
            ],
            scope: .weekly
        )

        #expect(progress.completedUnits == 5)
        #expect(progress.totalUnits == 6)
        #expect(progress.percentage == 83)
    }

    @Test func weeklyCompletedHabitsNeedsEveryRepetitionOfEveryDay() {
        let partial = useCase.execute(
            habits: [
                makeTodayHabit(
                    frequency: .weeklyCount(timesPerWeek: 2),
                    repetitionsPerDay: 2,
                    completedToday: 1,
                    completedDays: 1
                )
            ],
            scope: .weekly
        )
        let finished = useCase.execute(
            habits: [
                makeTodayHabit(
                    frequency: .weeklyCount(timesPerWeek: 2),
                    repetitionsPerDay: 2,
                    completedDays: 2
                )
            ],
            scope: .weekly
        )

        #expect(partial.completedUnits == 3)
        #expect(partial.totalUnits == 4)
        #expect(partial.completedHabits == 0)
        #expect(finished.completedUnits == 4)
        #expect(finished.completedHabits == 1)
    }

    @Test func weeklyIgnoresHabitsWithoutAWeeklyTarget() {
        let progress = useCase.execute(
            habits: [
                makeTodayHabit(frequency: .daily, completedToday: 1),
                makeTodayHabit(frequency: .fixedDays(weekdays: [2, 4]), completedToday: 1),
                makeTodayHabit(frequency: .weeklyCount(timesPerWeek: 2), completedDays: 1)
            ],
            scope: .weekly
        )

        #expect(progress.totalHabits == 1)
        #expect(progress.completedUnits == 1)
        #expect(progress.totalUnits == 2)
        #expect(progress.percentage == 50)
    }

    @Test func emptyListIsZeroWithoutDividingByZero() {
        let progress = useCase.execute(habits: [], scope: .daily)

        #expect(progress.completedHabits == 0)
        #expect(progress.totalHabits == 0)
        #expect(progress.completedUnits == 0)
        #expect(progress.totalUnits == 0)
        #expect(progress.fraction == 0)
        #expect(progress.percentage == 0)
    }

    @Test func fullyCompletedIsOneHundred() {
        let progress = useCase.execute(
            habits: [
                makeTodayHabit(repetitionsPerDay: 2, completedToday: 2),
                makeTodayHabit(repetitionsPerDay: 3, completedToday: 3)
            ],
            scope: .daily
        )

        #expect(progress.completedHabits == 2)
        #expect(progress.fraction == 1)
        #expect(progress.percentage == 100)
    }

    @Test(arguments: [(1, 33), (2, 67)])
    func percentageRounds(completedToday: Int, expected: Int) {
        let progress = useCase.execute(
            habits: [makeTodayHabit(repetitionsPerDay: 3, completedToday: completedToday)],
            scope: .daily
        )

        #expect(progress.percentage == expected)
    }

    @Test func progressNeverExceedsOneHundred() {
        let daily = useCase.execute(
            habits: [makeTodayHabit(repetitionsPerDay: 1, completedToday: 3)],
            scope: .daily
        )
        let weekly = useCase.execute(
            habits: [
                makeTodayHabit(
                    frequency: .weeklyCount(timesPerWeek: 2),
                    repetitionsPerDay: 2,
                    completedToday: 5,
                    completedDays: 4
                )
            ],
            scope: .weekly
        )

        #expect(daily.completedUnits == 1)
        #expect(daily.percentage == 100)
        #expect(weekly.completedUnits == 4)
        #expect(weekly.totalUnits == 4)
        #expect(weekly.percentage == 100)
    }
}
