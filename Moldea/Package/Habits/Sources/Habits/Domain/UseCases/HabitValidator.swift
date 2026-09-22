//
//  HabitValidator.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Core

enum HabitValidator {
    private static let weekdays = 1...7
    private static let timesPerWeek = 1...7

    static func validate(
        trimmedName: String,
        color: String,
        frequency: HabitFrequency,
        repetitionsPerDay: Int
    ) throws {
        guard !trimmedName.isEmpty else {
            throw CreateHabitError.emptyName
        }
        guard isHexColor(color) else {
            throw CreateHabitError.invalidColor
        }
        guard repetitionsPerDay >= 1 else {
            throw CreateHabitError.invalidRepetitionsPerDay
        }
        switch frequency {
        case .daily:
            break
        case .weeklyCount(let timesPerWeek):
            guard Self.timesPerWeek.contains(timesPerWeek) else {
                throw CreateHabitError.invalidTimesPerWeek
            }
        case .fixedDays(let weekdays):
            guard !weekdays.isEmpty else {
                throw CreateHabitError.emptyWeekdays
            }
            guard weekdays.allSatisfy(Self.weekdays.contains) else {
                throw CreateHabitError.invalidWeekdays
            }
        }
    }

    private static func isHexColor(_ value: String) -> Bool {
        value.count == 7
            && value.hasPrefix("#")
            && value.dropFirst().allSatisfy { $0.isASCII && $0.isHexDigit }
    }
}
