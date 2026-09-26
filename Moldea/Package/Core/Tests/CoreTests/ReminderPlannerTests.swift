import Testing
import Foundation
@testable import Core

struct ReminderPlannerTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }

    /// Miércoles 24 de junio de 2026, 12:00 en Madrid.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 12))!
    }

    private func time(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: hour, minute: minute))!
    }

    private func candidate(
        id: UUID = UUID(),
        hour: Int = 21,
        frequency: HabitFrequency = .daily,
        isActive: Bool = true,
        isEnabled: Bool = true,
        isMutedOnWeekends: Bool = false,
        isCompletedToday: Bool = false
    ) -> ReminderCandidate {
        ReminderCandidate(
            habit: Habit(
                id: id,
                name: "Leer",
                color: "#007AFF",
                icon: "book",
                isActive: isActive,
                createdAt: .now,
                updatedAt: .now,
                schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: 1),
                reminder: HabitReminder(time: time(hour), isEnabled: isEnabled, isMutedOnWeekends: isMutedOnWeekends)
            ),
            isCompletedToday: isCompletedToday
        )
    }

    private func plan(
        _ candidates: [ReminderCandidate],
        budget: Int = 60,
        horizonDays: Int = 7
    ) -> [PlannedReminder] {
        ReminderPlanner.plan(
            candidates: candidates,
            now: now,
            calendar: calendar,
            budget: budget,
            horizonDays: horizonDays
        )
    }

    // MARK: Hoy

    @Test func todayIsPlannedWhenTheReminderTimeHasNotPassed() {
        let planned = plan([candidate(hour: 21)])

        #expect(planned.count == 7)
        #expect(planned.first?.fireDate == calendar.date(from: DateComponents(year: 2026, month: 6, day: 24, hour: 21)))
    }

    @Test func todayIsSkippedWhenTheReminderTimeHasPassed() {
        let planned = plan([candidate(hour: 9)])

        #expect(planned.count == 6)
        #expect(planned.first?.fireDate == calendar.date(from: DateComponents(year: 2026, month: 6, day: 25, hour: 9)))
    }

    @Test func aHabitCompletedTodaySkipsOnlyToday() {
        let planned = plan([candidate(hour: 21, isCompletedToday: true)])

        #expect(planned.count == 6)
        #expect(planned.first?.fireDate == calendar.date(from: DateComponents(year: 2026, month: 6, day: 25, hour: 21)))
    }

    @Test func undoingTheCompletionPlansTodayAgain() {
        let id = UUID()
        let completed = plan([candidate(id: id, isCompletedToday: true)])
        let reset = plan([candidate(id: id, isCompletedToday: false)])

        #expect(reset.count == completed.count + 1)
        #expect(reset.first?.identifier == ReminderPlanner.identifier(habitID: id, day: now, calendar: calendar))
    }

    // MARK: Qué hábitos entran

    @Test func pausedHabitsAndDisabledRemindersAreNotPlanned() {
        #expect(plan([candidate(isActive: false)]).isEmpty)
        #expect(plan([candidate(isEnabled: false)]).isEmpty)
    }

    @Test func habitsWithoutAReminderAreNotPlanned() {
        let habit = Habit(
            id: UUID(), name: "Leer", color: "#007AFF", icon: "book", isActive: true,
            createdAt: .now, updatedAt: .now,
            schedule: HabitSchedule(frequency: .daily, repetitionsPerDay: 1), reminder: nil
        )

        #expect(plan([ReminderCandidate(habit: habit, isCompletedToday: false)]).isEmpty)
    }

    @Test func fixedDaysOnlyPlanThoseWeekdays() {
        // 4 = miércoles, 6 = viernes. Hoy es miércoles.
        let planned = plan([candidate(frequency: .fixedDays(weekdays: [4, 6]))], horizonDays: 14)
        let weekdays = planned.map { calendar.component(.weekday, from: $0.fireDate) }

        #expect(Set(weekdays) == [4, 6])
        #expect(planned.count == 4)
    }

    @Test func mutedWeekendsSkipSaturdayAndSunday() {
        let planned = plan([candidate(isMutedOnWeekends: true)], horizonDays: 14)
        let weekdays = Set(planned.map { calendar.component(.weekday, from: $0.fireDate) })

        #expect(!weekdays.contains(1))
        #expect(!weekdays.contains(7))
    }

    // MARK: Identificadores

    @Test func identifiersAreUniquePerHabitAndDay() {
        let planned = plan([candidate(), candidate()], horizonDays: 7)

        #expect(Set(planned.map(\.identifier)).count == planned.count)
    }

    @Test func identifiersEncodeHabitAndDate() {
        let id = UUID()
        let identifier = ReminderPlanner.identifier(habitID: id, day: now, calendar: calendar)

        #expect(identifier == "habit-reminder-\(id.uuidString)-20260624")
    }

    // MARK: Presupuesto

    @Test func theBudgetKeepsTheNearestNotificationsOfEveryHabit() {
        let first = candidate(hour: 20)
        let second = candidate(hour: 21)

        let planned = plan([first, second], budget: 4, horizonDays: 7)

        // Días 24 y 25 de los dos hábitos: mismo horizonte para ambos.
        #expect(planned.count == 4)
        #expect(Set(planned.map(\.habitID)) == [first.habit.id, second.habit.id])
        let lastDay = planned.map(\.fireDate).max()!
        #expect(calendar.component(.day, from: lastDay) == 25)
    }

    @Test func aZeroBudgetPlansNothing() {
        #expect(plan([candidate()], budget: 0).isEmpty)
    }

    @Test func theResultIsSortedByFireDate() {
        let planned = plan([candidate(hour: 22), candidate(hour: 13)], horizonDays: 3)

        #expect(planned.map(\.fireDate) == planned.map(\.fireDate).sorted())
    }

    // MARK: Cambio de hora

    @Test func theReminderKeepsItsLocalTimeAcrossTheDaylightSavingChange() {
        // El cambio de hora en España fue el 29 de marzo de 2026.
        let march = calendar.date(from: DateComponents(year: 2026, month: 3, day: 27, hour: 12))!
        let planned = ReminderPlanner.plan(
            candidates: [candidate(hour: 21)],
            now: march,
            calendar: calendar,
            budget: 60,
            horizonDays: 5
        )

        let hours = planned.map { calendar.component(.hour, from: $0.fireDate) }
        #expect(hours == [21, 21, 21, 21, 21])
    }
}
