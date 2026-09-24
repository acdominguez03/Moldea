import Testing
import Foundation
import Core
@testable import Statistics

private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    return calendar
}

private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
}

private func makeTodayHabit(
    frequency: HabitFrequency = .daily,
    completedDays: [Date] = [],
    referenceDay: Date
) -> TodayHabit {
    let habit = Habit(
        id: UUID(),
        name: "Leer",
        color: "#5B6470",
        icon: "book",
        isActive: true,
        createdAt: .distantPast,
        updatedAt: .distantPast,
        schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: 1)
    )
    let completions = completedDays.map {
        HabitCompletion(id: UUID(), habitID: habit.id, day: $0, repetitionIndex: 0, completedAt: $0)
    }
    return TodayHabit(habit: habit, completions: completions, referenceDay: referenceDay, calendar: calendar)
}

private func days(from start: Date, count: Int) -> [Date] {
    (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
}

struct HabitOccurrencesBuilderTests {
    private let builder = HabitOccurrencesBuilder(calendar: calendar)

    @Test func februaryIsSplitInFourWeeksOfSevenDays() {
        let buckets = builder.monthBuckets(containing: date(2026, 2, 10))

        #expect(buckets.map(\.start) == [date(2026, 2, 1), date(2026, 2, 8), date(2026, 2, 15), date(2026, 2, 22)])
        #expect(buckets.last?.end == date(2026, 3, 1))
    }

    @Test func lastWeekOfALongMonthRunsUntilTheEndOfTheMonth() {
        let buckets = builder.monthBuckets(containing: date(2026, 8, 3))

        #expect(buckets.count == 4)
        #expect(buckets.last?.start == date(2026, 8, 22))
        #expect(buckets.last?.end == date(2026, 9, 1))
    }

    @Test func futureDaysAreNotExpected() {
        let today = date(2026, 9, 3)
        let habit = makeTodayHabit(referenceDay: today)
        let firstWeek = builder.monthBuckets(containing: today)[0]
        let lastWeek = builder.monthBuckets(containing: today)[3]

        #expect(builder.occurrences(of: [habit], in: firstWeek, until: today).count == 3)
        #expect(builder.occurrences(of: [habit], in: lastWeek, until: today).isEmpty)
    }

    @Test func weeklyCountHabitHasOneTargetPerStartedWeek() {
        let today = date(2026, 9, 10)
        let habit = makeTodayHabit(
            frequency: .weeklyCount(timesPerWeek: 2),
            completedDays: [date(2026, 9, 2), date(2026, 9, 5)],
            referenceDay: today
        )
        let occurrences = builder.monthOccurrences(of: [habit], containing: today, until: today)
        let progress = CalculateHabitsProgressUseCase().execute(habits: occurrences, scope: .all)

        #expect(occurrences.count == 2)
        #expect(progress.completedUnits == 2)
        #expect(progress.totalUnits == 4)
    }
}

struct MonthChartViewModelTests {
    @Test func weeksAndHabitShowMonthlyProgressUntilToday() {
        let today = date(2026, 9, 10)
        let habit = makeTodayHabit(completedDays: days(from: date(2026, 9, 1), count: 7), referenceDay: today)
        let viewModel = MonthChartViewModel(calculateHabitProgressUseCase: CalculateHabitsProgressUseCase(), calendar: calendar)

        viewModel.getMonthlyPercentages(habits: [habit], date: today)

        #expect(viewModel.data.map(\.percentage) == [100, 0, 0, 0])
        #expect(viewModel.totalProgress == 70)
        #expect(viewModel.percentage(for: habit, date: today) == 70)
    }
}

struct YearChartViewModelTests {
    @Test func monthsAndHabitShowYearlyProgressUntilToday() {
        let today = date(2026, 2, 28)
        let habit = makeTodayHabit(completedDays: days(from: date(2026, 1, 1), count: 31), referenceDay: today)
        let viewModel = YearChartViewModel(calculateHabitProgressUseCase: CalculateHabitsProgressUseCase(), calendar: calendar)

        viewModel.getYearlyPercentages(habits: [habit], date: today)

        #expect(viewModel.data.count == 12)
        #expect(viewModel.data.map(\.percentage) == [100] + Array(repeating: 0, count: 11))
        #expect(viewModel.totalProgress == 53)
        #expect(viewModel.percentage(for: habit, date: today) == 53)
    }
}

struct DayOccurrencesTests {
    private let builder = HabitOccurrencesBuilder(calendar: calendar)

    @Test func lastTenDaysEndTodayAndCrossTheMonth() {
        let lastDays = builder.lastDays(10, until: date(2026, 9, 3))

        #expect(lastDays.count == 10)
        #expect(lastDays.first == date(2026, 8, 25))
        #expect(lastDays.last == date(2026, 9, 3))
    }

    @Test func onlyHabitsScheduledThatDayAreExpected() {
        let day = date(2026, 9, 10)
        let daily = makeTodayHabit(completedDays: [date(2026, 9, 9), day], referenceDay: day)
        let weekly = makeTodayHabit(frequency: .weeklyCount(timesPerWeek: 3), referenceDay: day)
        let otherDay = makeTodayHabit(frequency: .fixedDays(weekdays: [2]), referenceDay: day)

        let occurrences = builder.occurrences(of: [daily, weekly, otherDay], on: day)

        #expect(occurrences.map(\.id) == [daily.id])
        #expect(occurrences.first?.completions.count == 1)
    }
}

struct DayChartViewModelTests {
    @Test func selectedDayShowsItsOwnProgress() {
        let today = date(2026, 9, 10)
        let done = makeTodayHabit(completedDays: [date(2026, 9, 9)], referenceDay: today)
        let pending = makeTodayHabit(referenceDay: today)
        let viewModel = DayChartViewModel(
            calculateHabitProgressUseCase: CalculateHabitsProgressUseCase(),
            calendar: calendar,
            today: today
        )

        viewModel.getDailyPercentages(habits: [done, pending])
        #expect(viewModel.days.count == 10)
        #expect(viewModel.selectedDay == today)
        #expect(viewModel.totalProgress == 0)

        let yesterday = viewModel.days[8]
        viewModel.select(yesterday, habits: [done, pending])

        #expect(yesterday.number == 9)
        #expect(viewModel.totalProgress == 50)
        #expect(viewModel.dayHabits.map { viewModel.percentage(for: $0) } == [100, 0])
    }
}
