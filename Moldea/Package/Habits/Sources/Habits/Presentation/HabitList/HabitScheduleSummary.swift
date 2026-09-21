//
//  HabitScheduleSummary.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Foundation
import Core

/// Lo que se muestra bajo el nombre del hábito en la lista. Se separa de la vista para poder
/// testear las reglas sin renderizar nada.
enum HabitScheduleSummary: Equatable {
    case everyDay
    case timesPerDay(Int)
    /// Símbolos de los días, en el orden de la semana del calendario.
    case weekdays([String])
    case timesPerWeek(Int)

    init(schedule: HabitSchedule, calendar: Calendar = .current) {
        switch schedule.frequency {
        case .daily:
            self = schedule.repetitionsPerDay > 1
                ? .timesPerDay(schedule.repetitionsPerDay)
                : .everyDay
        case .weeklyCount(let timesPerWeek):
            self = .timesPerWeek(timesPerWeek)
        case .fixedDays(let weekdays):
            self = .weekdays(Self.symbols(for: weekdays, calendar: calendar))
        }
    }

    private static func symbols(for weekdays: Set<Int>, calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let offset = { (weekday: Int) in (weekday - calendar.firstWeekday + 7) % 7 }

        return weekdays
            .filter { symbols.indices.contains($0 - 1) }
            .sorted { offset($0) < offset($1) }
            .map { symbols[$0 - 1] }
    }
}
