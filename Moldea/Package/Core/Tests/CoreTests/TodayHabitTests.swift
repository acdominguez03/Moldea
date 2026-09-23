import Testing
import Foundation
@testable import Core

struct TodayHabitTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let referenceDay = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeTodayHabit(
        frequency: HabitFrequency = .daily,
        repetitionsPerDay: Int = 1,
        completionsPerDayOffset: [Int: Int]
    ) -> TodayHabit {
        let day = calendar.startOfDay(for: referenceDay)
        let habit = makeHabit(
            name: "Beber agua",
            frequency: frequency,
            repetitionsPerDay: repetitionsPerDay
        )
        let completions = completionsPerDayOffset.flatMap { offset, count in
            let completionDay = calendar.date(byAdding: .day, value: offset, to: day) ?? day
            return (0..<count).map { repetitionIndex in
                HabitCompletion(
                    id: UUID(),
                    habitID: habit.id,
                    day: completionDay,
                    repetitionIndex: repetitionIndex,
                    completedAt: completionDay
                )
            }
        }

        return TodayHabit(
            habit: habit,
            completions: completions,
            referenceDay: day,
            calendar: calendar
        )
    }

    @Test func completedTodayOnlyCountsTheReferenceDay() {
        let todayHabit = makeTodayHabit(
            repetitionsPerDay: 4,
            completionsPerDayOffset: [0: 2, -1: 4, -2: 4]
        )

        #expect(todayHabit.completedToday == 2)
        #expect(todayHabit.isCompletedToday == false)
    }

    @Test func isCompletedTodayWhenEveryRepetitionIsDone() {
        let todayHabit = makeTodayHabit(repetitionsPerDay: 4, completionsPerDayOffset: [0: 4])

        #expect(todayHabit.isCompletedToday)
    }

    @Test func completedDaysThisWeekIgnoresDaysWithRepetitionsLeft() {
        let todayHabit = makeTodayHabit(
            frequency: .weeklyCount(timesPerWeek: 3),
            repetitionsPerDay: 2,
            completionsPerDayOffset: [-2: 2, -1: 1, 0: 2]
        )

        #expect(todayHabit.completedDaysThisWeek == 2)
    }

    @Test func completedDaysThisWeekIsCappedAtTimesPerWeek() {
        let todayHabit = makeTodayHabit(
            frequency: .weeklyCount(timesPerWeek: 2),
            completionsPerDayOffset: [-3: 1, -2: 1, -1: 1, 0: 1]
        )

        #expect(todayHabit.completedDaysThisWeek == 2)
    }

    @Test func completedRepetitionsThisWeekCountsPartialDays() {
        let todayHabit = makeTodayHabit(
            frequency: .weeklyCount(timesPerWeek: 3),
            repetitionsPerDay: 2,
            completionsPerDayOffset: [-2: 2, -1: 1, 0: 2]
        )

        #expect(todayHabit.completedRepetitionsThisWeek == 5)
        #expect(todayHabit.completedDaysThisWeek == 2)
    }

    @Test func completedRepetitionsThisWeekIsCappedAtTheWeeklyTarget() {
        let todayHabit = makeTodayHabit(
            frequency: .weeklyCount(timesPerWeek: 2),
            repetitionsPerDay: 2,
            completionsPerDayOffset: [-3: 2, -2: 2, -1: 3, 0: 2]
        )

        #expect(todayHabit.completedRepetitionsThisWeek == 4)
    }

    @Test func idIsTheHabitID() {
        let todayHabit = makeTodayHabit(completionsPerDayOffset: [:])

        #expect(todayHabit.id == todayHabit.habit.id)
        #expect(todayHabit.completedToday == 0)
        #expect(todayHabit.completedDaysThisWeek == 0)
    }
}
