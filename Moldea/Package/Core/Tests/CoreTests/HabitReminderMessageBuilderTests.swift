import Testing
import Foundation
@testable import Core

struct HabitReminderMessageBuilderTests {
    private func resolve(_ resource: LocalizedStringResource, locale: String = "es") -> String {
        var resource = resource
        resource.locale = Locale(identifier: locale)
        return String(localized: resource)
    }

    @Test func bodyForDailyWithOneRepetition() {
        let body = HabitReminderMessageBuilder.body(frequency: .daily, repetitionsPerDay: 1)

        #expect(resolve(body) == "Es tu momento de hoy. Márcalo cuando lo hagas.")
    }

    @Test func bodyForDailyWithMultipleRepetitions() {
        let body = HabitReminderMessageBuilder.body(frequency: .daily, repetitionsPerDay: 3)

        #expect(resolve(body) == "Hoy son 3 veces. ¿Empezamos?")
    }

    @Test func bodyForWeeklyCount() {
        let body = HabitReminderMessageBuilder.body(
            frequency: .weeklyCount(timesPerWeek: 4),
            repetitionsPerDay: 1
        )

        #expect(resolve(body) == "Tu objetivo es 4 veces esta semana. Si hoy te encaja, adelante.")
    }

    @Test func bodyForFixedDays() {
        let body = HabitReminderMessageBuilder.body(
            frequency: .fixedDays(weekdays: [2, 4, 6]),
            repetitionsPerDay: 1
        )

        #expect(resolve(body) == "Hoy es uno de tus días. Tú decides cuándo.")
    }

    @Test func weekdaysForDailyWithoutMutingWeekends() {
        let weekdays = HabitReminderMessageBuilder.weekdays(frequency: .daily, isMutedOnWeekends: false)

        #expect(weekdays == [1, 2, 3, 4, 5, 6, 7])
    }

    @Test func weekdaysForDailyMutingWeekends() {
        let weekdays = HabitReminderMessageBuilder.weekdays(frequency: .daily, isMutedOnWeekends: true)

        #expect(weekdays == [2, 3, 4, 5, 6])
    }

    @Test func weekdaysForWeeklyCountMutingWeekends() {
        let weekdays = HabitReminderMessageBuilder.weekdays(
            frequency: .weeklyCount(timesPerWeek: 3),
            isMutedOnWeekends: true
        )

        #expect(weekdays == [2, 3, 4, 5, 6])
    }

    @Test func weekdaysForFixedDaysKeepsOnlyTheChosenDays() {
        let weekdays = HabitReminderMessageBuilder.weekdays(
            frequency: .fixedDays(weekdays: [1, 3, 7]),
            isMutedOnWeekends: false
        )

        #expect(weekdays == [1, 3, 7])
    }

    @Test func weekdaysForFixedDaysMutingWeekendsRemovesSaturdayAndSunday() {
        let weekdays = HabitReminderMessageBuilder.weekdays(
            frequency: .fixedDays(weekdays: [1, 3, 7]),
            isMutedOnWeekends: true
        )

        #expect(weekdays == [3])
    }
}
