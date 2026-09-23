//
//  HabitReminderMessageBuilder.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

import Foundation

enum HabitReminderMessageBuilder {
    static func body(frequency: HabitFrequency, repetitionsPerDay: Int) -> String {
        switch frequency {
        case .daily:
            return repetitionsPerDay > 1
                ? String(localized: CoreTextsEnum.habitReminderDailyMultipleBody(repetitionsPerDay))
                : String(localized: CoreTextsEnum.habitReminderDailySingleBody)
        case .weeklyCount(let timesPerWeek):
            return String(localized: CoreTextsEnum.habitReminderWeeklyCountBody(timesPerWeek))
        case .fixedDays:
            return String(localized: CoreTextsEnum.habitReminderFixedDaysBody)
        }
    }

    static func weekdays(frequency: HabitFrequency, isMutedOnWeekends: Bool) -> Set<Int> {
        let allWeekdays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
        let scheduledWeekdays: Set<Int>

        switch frequency {
        case .daily, .weeklyCount:
            scheduledWeekdays = allWeekdays
        case .fixedDays(let weekdays):
            scheduledWeekdays = weekdays
        }

        guard isMutedOnWeekends else { return scheduledWeekdays }
        return scheduledWeekdays.subtracting([1, 7])
    }
}
