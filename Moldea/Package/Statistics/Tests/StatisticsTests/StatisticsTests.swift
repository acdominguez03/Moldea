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
    inactivePeriods: [HabitInactivePeriod] = [],
    referenceDay: Date
) -> TodayHabit {
    let habit = Habit(
        id: UUID(),
        name: "Leer",
        color: "#5B6470",
        icon: "book",
        isActive: !inactivePeriods.contains(where: \.isOpen),
        createdAt: .distantPast,
        updatedAt: .distantPast,
        schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: 1),
        inactivePeriods: inactivePeriods
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

struct InactivePeriodOccurrencesTests {
    private let builder = HabitOccurrencesBuilder(calendar: calendar)
    private let week = DateInterval(start: date(2026, 9, 6), end: date(2026, 9, 13))

    @Test func inactiveDaysAreNotExpected() {
        let habit = makeTodayHabit(
            inactivePeriods: [HabitInactivePeriod(start: date(2026, 9, 8), end: date(2026, 9, 10))],
            referenceDay: date(2026, 9, 10)
        )

        #expect(builder.occurrences(of: [habit], on: date(2026, 9, 7)).count == 1)
        #expect(builder.occurrences(of: [habit], on: date(2026, 9, 9)).isEmpty)
        #expect(builder.occurrences(of: [habit], on: date(2026, 9, 10)).count == 1)
        #expect(builder.occurrences(of: [habit], in: week, until: date(2026, 9, 12)).count == 5)
    }

    @Test func weeklyTargetIsProratedByActiveDays() throws {
        let habit = makeTodayHabit(
            frequency: .weeklyCount(timesPerWeek: 3),
            completedDays: [date(2026, 9, 7), date(2026, 9, 11)],
            inactivePeriods: [HabitInactivePeriod(start: date(2026, 9, 10))],
            referenceDay: date(2026, 9, 11)
        )

        let occurrence = try #require(builder.weeklyOccurrence(of: habit, in: week))

        #expect(occurrence.habit.schedule.frequency == .weeklyCount(timesPerWeek: 2))
        #expect(occurrence.completions.map(\.day) == [date(2026, 9, 7)])
    }

    @Test func fullyActiveWeekKeepsItsTarget() throws {
        let habit = makeTodayHabit(frequency: .weeklyCount(timesPerWeek: 3), referenceDay: date(2026, 9, 11))

        let occurrence = try #require(builder.weeklyOccurrence(of: habit, in: week))

        #expect(occurrence.habit.schedule.frequency == .weeklyCount(timesPerWeek: 3))
    }

    @Test func habitInactiveTheWholeWeekIsNotShown() {
        let today = date(2026, 9, 10)
        let inactive = makeTodayHabit(
            frequency: .weeklyCount(timesPerWeek: 3),
            inactivePeriods: [HabitInactivePeriod(start: date(2026, 9, 1))],
            referenceDay: today
        )
        let active = makeTodayHabit(referenceDay: today)
        let viewModel = WeekChartViewModel(calculateHabitProgressUseCase: CalculateHabitsProgressUseCase(), calendar: calendar)

        viewModel.getWeeklyPercentages(habits: [inactive, active], date: today)

        #expect(builder.weeklyOccurrence(of: inactive, in: week) == nil)
        #expect(viewModel.visibleHabits.map(\.id) == [active.id])
        #expect(viewModel.weeklyStatistic == nil)
    }
}

struct ChartSelectionTests {
    private let useCase = CalculateHabitsProgressUseCase()

    @Test func selectingADayFiltersTheWeekAndSelectingItAgainRestoresIt() throws {
        let today = date(2026, 9, 10)
        let yesterday = date(2026, 9, 9)
        let daily = makeTodayHabit(completedDays: [yesterday], referenceDay: today)
        let otherDay = makeTodayHabit(
            frequency: .fixedDays(weekdays: [calendar.component(.weekday, from: today)]),
            referenceDay: today
        )
        let weekly = makeTodayHabit(frequency: .weeklyCount(timesPerWeek: 2), referenceDay: today)
        let habits = [daily, otherDay, weekly]
        let viewModel = WeekChartViewModel(calculateHabitProgressUseCase: useCase, calendar: calendar)
        viewModel.getWeeklyPercentages(habits: habits, date: today)
        let week = try #require(calendar.dateInterval(of: .weekOfYear, for: today))
        let yesterdayBar = try #require(viewModel.data.first { $0.interval?.start == yesterday })

        #expect(viewModel.summaryInterval == week)
        #expect(viewModel.summaryPercentage == viewModel.totalProgress)

        viewModel.select(yesterdayBar.id, habits: habits, date: today)

        #expect(viewModel.selectedStatisticID == yesterdayBar.id)
        #expect(viewModel.summaryInterval == calendar.dateInterval(of: .day, for: yesterday))
        #expect(viewModel.summaryPercentage == 100)
        #expect(viewModel.visibleHabits.map(\.id) == [daily.id])
        #expect(viewModel.percentage(for: daily, date: today) == 100)

        viewModel.select(yesterdayBar.id, habits: habits, date: today)

        #expect(viewModel.selectedStatisticID == nil)
        #expect(viewModel.summaryInterval == week)
        #expect(viewModel.summaryPercentage == viewModel.totalProgress)
        #expect(viewModel.visibleHabits.count == 3)
    }

    @Test func selectingTheWeeklyBarShowsOnlyWeeklyCountHabits() {
        let today = date(2026, 9, 10)
        let daily = makeTodayHabit(referenceDay: today)
        let weekly = makeTodayHabit(frequency: .weeklyCount(timesPerWeek: 2), referenceDay: today)
        let viewModel = WeekChartViewModel(calculateHabitProgressUseCase: useCase, calendar: calendar)
        viewModel.getWeeklyPercentages(habits: [daily, weekly], date: today)

        viewModel.select("weekly", habits: [daily, weekly], date: today)

        #expect(viewModel.visibleHabits.map(\.id) == [weekly.id])

        viewModel.clearSelection(habits: [daily, weekly], date: today)

        #expect(viewModel.selectedStatisticID == nil)
        #expect(viewModel.visibleHabits.count == 2)
    }

    @Test func futureDayCannotBeSelected() throws {
        let today = date(2026, 9, 10)
        let habit = makeTodayHabit(referenceDay: today)
        let viewModel = WeekChartViewModel(calculateHabitProgressUseCase: useCase, calendar: calendar)
        viewModel.getWeeklyPercentages(habits: [habit], date: today)
        let tomorrowBar = try #require(viewModel.data.first { $0.interval?.start == date(2026, 9, 11) })

        viewModel.select(tomorrowBar.id, habits: [habit], date: today)

        #expect(viewModel.selectedStatisticID == nil)
    }

    @Test func selectingAMonthBucketUsesItsDays() {
        let today = date(2026, 9, 10)
        let habit = makeTodayHabit(completedDays: days(from: date(2026, 9, 1), count: 7), referenceDay: today)
        let viewModel = MonthChartViewModel(calculateHabitProgressUseCase: useCase, calendar: calendar)
        viewModel.getMonthlyPercentages(habits: [habit], date: today)

        #expect(viewModel.summaryInterval == calendar.dateInterval(of: .month, for: today))

        viewModel.select("week_2", habits: [habit], date: today)

        #expect(viewModel.summaryInterval == DateInterval(start: date(2026, 9, 8), end: date(2026, 9, 15)))
        #expect(viewModel.summaryPercentage == 0)
        #expect(viewModel.percentage(for: habit, date: today) == 0)

        viewModel.select("week_1", habits: [habit], date: today)

        #expect(viewModel.summaryPercentage == 100)
        #expect(viewModel.percentage(for: habit, date: today) == 100)

        viewModel.select("week_3", habits: [habit], date: today)

        #expect(viewModel.selectedStatisticID == "week_1")
    }

    @Test func selectingAMonthUsesItsOccurrences() {
        let today = date(2026, 2, 28)
        let habit = makeTodayHabit(completedDays: days(from: date(2026, 1, 1), count: 31), referenceDay: today)
        let viewModel = YearChartViewModel(calculateHabitProgressUseCase: useCase, calendar: calendar)
        viewModel.getYearlyPercentages(habits: [habit], date: today)

        #expect(viewModel.summaryInterval == calendar.dateInterval(of: .year, for: today))

        viewModel.select("month_1", habits: [habit], date: today)

        #expect(viewModel.summaryInterval == DateInterval(start: date(2026, 1, 1), end: date(2026, 2, 1)))
        #expect(viewModel.summaryPercentage == 100)
        #expect(viewModel.percentage(for: habit, date: today) == 100)

        viewModel.clearSelection(habits: [habit], date: today)

        #expect(viewModel.summaryPercentage == 53)
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

struct ChartAccessibilityTitleTests {
    private var spanishCalendar: Calendar {
        var calendar = calendar
        calendar.locale = Locale(identifier: "es_ES")
        calendar.firstWeekday = 2
        return calendar
    }

    @Test func weekBarsUseFullWeekdayNamesStartingOnFirstWeekday() {
        let viewModel = WeekChartViewModel(
            calculateHabitProgressUseCase: CalculateHabitsProgressUseCase(),
            calendar: spanishCalendar
        )

        #expect(viewModel.data.map(\.accessibilityTitle) == spanishCalendar.standaloneWeekdaySymbols.rotated(by: 1))
        #expect(viewModel.data.allSatisfy { $0.title != $0.accessibilityTitle })
    }

    @Test func yearBarsUseFullMonthNames() {
        let viewModel = YearChartViewModel(
            calculateHabitProgressUseCase: CalculateHabitsProgressUseCase(),
            calendar: spanishCalendar
        )

        #expect(viewModel.data.map(\.accessibilityTitle) == spanishCalendar.standaloneMonthSymbols)
    }

    @Test func monthBarsHaveOneDistinctNamePerWeek() {
        let viewModel = MonthChartViewModel(
            calculateHabitProgressUseCase: CalculateHabitsProgressUseCase(),
            calendar: spanishCalendar
        )
        let titles = viewModel.data.map(\.accessibilityTitle)

        #expect(titles.count == 4)
        #expect(Set(titles).count == 4)
        #expect(titles.allSatisfy { !$0.isEmpty })
    }

    @Test func tierFollowsPercentageThresholds() {
        func tier(_ percentage: Int) -> HabitStatistic.TierEnum {
            HabitStatistic(id: "x", title: "x", accessibilityTitle: "x", percentage: percentage).tier
        }

        #expect(tier(59) == .low)
        #expect(tier(60) == .medium)
        #expect(tier(79) == .medium)
        #expect(tier(80) == .high)
        #expect(HabitStatistic(id: "w", title: "w", accessibilityTitle: "w", percentage: 10, kind: .weekly).tier == .weekly)
    }
}

private extension Array {
    func rotated(by offset: Int) -> [Element] {
        Array(self[offset...] + self[..<offset])
    }
}
