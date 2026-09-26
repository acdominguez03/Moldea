import Testing
import Foundation
@testable import Core

struct HabitScheduleSummaryTests {
    /// Calendario gregoriano con la semana empezando en `firstWeekday` y símbolos del idioma dado.
    private func makeCalendar(locale: String, firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: locale)
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func summary(
        _ frequency: HabitFrequency,
        repetitionsPerDay: Int = 1,
        calendar: Calendar? = nil
    ) -> HabitScheduleSummaryEnum {
        HabitScheduleSummaryEnum(
            schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: repetitionsPerDay),
            calendar: calendar ?? makeCalendar(locale: "es_ES", firstWeekday: 2)
        )
    }

    private func resolve(_ resource: LocalizedStringResource, locale: String) -> String {
        var resource = resource
        resource.locale = Locale(identifier: locale)
        return String(localized: resource)
    }

    // MARK: Reglas

    @Test func dailyOnceIsEveryDay() {
        #expect(summary(.daily) == .everyDay)
    }

    @Test func dailyManyTimesShowsTheCount() {
        #expect(summary(.daily, repetitionsPerDay: 3) == .timesPerDay(3))
    }

    @Test func weeklyCountShowsTheCount() {
        #expect(summary(.weeklyCount(timesPerWeek: 3)) == .timesPerWeek(3))
    }

    @Test func fixedDaysShowTheWeekdaySymbols() {
        #expect(summary(.fixedDays(weekdays: [2, 4, 6])) == .weekdays(["L", "X", "V"]))
    }

    @Test func fixedDaysFollowTheCalendarWeekOrder() {
        // Con la semana empezando en lunes, el domingo (1) va el último.
        #expect(summary(.fixedDays(weekdays: [1, 2])) == .weekdays(["L", "D"]))

        // Con la semana empezando en domingo, va el primero.
        let sundayFirst = makeCalendar(locale: "es_ES", firstWeekday: 1)
        #expect(summary(.fixedDays(weekdays: [1, 2]), calendar: sundayFirst) == .weekdays(["D", "L"]))
    }

    @Test func fixedDaysUseTheSymbolsOfTheCalendarLocale() {
        let english = makeCalendar(locale: "en_US", firstWeekday: 1)

        #expect(summary(.fixedDays(weekdays: [2, 4, 6]), calendar: english) == .weekdays(["M", "W", "F"]))
    }

    @Test func fixedDaysIgnoreValuesOutsideTheWeek() {
        #expect(summary(.fixedDays(weekdays: [2, 9])) == .weekdays(["L"]))
    }

    @Test func weekdayNamesAreFullAndFollowTheCalendarWeekOrder() {
        let schedule = HabitSchedule(frequency: .fixedDays(weekdays: [1, 2, 4]), repetitionsPerDay: 1)
        let calendar = makeCalendar(locale: "es_ES", firstWeekday: 2)

        #expect(HabitScheduleSummaryEnum.weekdayNames(of: schedule, calendar: calendar) == ["lunes", "miércoles", "domingo"])
    }

    @Test func weekdayNamesAreEmptyWithoutFixedDays() {
        let schedule = HabitSchedule(frequency: .daily, repetitionsPerDay: 1)

        #expect(HabitScheduleSummaryEnum.weekdayNames(of: schedule).isEmpty)
    }

    // MARK: Textos

    @Test(arguments: [
        (1, "1 vez por semana"),
        (3, "3 veces por semana"),
    ])
    func timesPerWeekTextInSpanish(count: Int, expected: String) {
        #expect(resolve(CoreTextsEnum.summaryTimesPerWeek(count), locale: "es") == expected)
    }

    @Test(arguments: [
        (1, "1 time a week"),
        (3, "3 times a week"),
    ])
    func timesPerWeekTextInEnglish(count: Int, expected: String) {
        #expect(resolve(CoreTextsEnum.summaryTimesPerWeek(count), locale: "en") == expected)
    }

    @Test func timesPerDayText() {
        #expect(resolve(CoreTextsEnum.summaryTimesPerDay(3), locale: "es") == "3 veces al día")
        #expect(resolve(CoreTextsEnum.summaryTimesPerDay(3), locale: "en") == "3 times a day")
    }

    @Test func everyDayText() {
        #expect(resolve(CoreTextsEnum.summaryEveryDay, locale: "es") == "Cada día")
        #expect(resolve(CoreTextsEnum.summaryEveryDay, locale: "en") == "Every day")
    }
}
