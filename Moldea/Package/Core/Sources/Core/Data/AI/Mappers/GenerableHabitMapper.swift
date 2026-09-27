//
//  GenerableHabitMapper.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

import Foundation

enum GenerableHabitMapper {
    static func draft(from generated: GenerableHabitDraft) throws -> NewHabitDraft {
        let name = generated.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw HabitCommandErrorEnum.notUnderstood
        }

        return NewHabitDraft(
            name: name,
            frequency: try frequency(from: generated),
            repetitionsPerDay: generated.repetitionsPerDay
        )
    }

    static func habitID(forName name: String, in habits: [Habit]) throws -> Habit.ID {
        let target = normalized(name)
        guard let habit = habits.first(where: { normalized($0.name) == target }) else {
            throw HabitCommandErrorEnum.habitNotFound
        }
        return habit.id
    }

    private static func frequency(from generated: GenerableHabitDraft) throws -> HabitFrequency {
        switch generated.frequency {
        case .daily:
            return .daily
        case .timesPerWeek:
            guard Self.validTimesPerWeek.contains(generated.timesPerWeek) else {
                throw HabitCommandErrorEnum.missingFrequencyData
            }
            return .weeklyCount(timesPerWeek: generated.timesPerWeek)
        case .fixedWeekdays:
            let weekdays = Set(generated.weekdays.map(calendarWeekday))
            guard !weekdays.isEmpty else {
                throw HabitCommandErrorEnum.missingFrequencyData
            }
            return .fixedDays(weekdays: weekdays)
        }
    }

    static func calendarWeekday(_ weekday: GenerableWeekdayEnum) -> Int {
        switch weekday {
        case .sunday: 1
        case .monday: 2
        case .tuesday: 3
        case .wednesday: 4
        case .thursday: 5
        case .friday: 6
        case .saturday: 7
        }
    }

    private static let validTimesPerWeek = 1...7

    private static func normalized(_ name: String) -> String {
        name
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .lowercased()
    }
}
