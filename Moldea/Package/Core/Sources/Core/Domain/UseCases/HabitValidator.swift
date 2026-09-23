//
//  HabitValidator.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

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
            throw CreateHabitErrorEnum.emptyName
        }
        guard isHexColor(color) else {
            throw CreateHabitErrorEnum.invalidColor
        }
        guard repetitionsPerDay >= 1 else {
            throw CreateHabitErrorEnum.invalidRepetitionsPerDay
        }
        switch frequency {
        case .daily:
            break
        case .weeklyCount(let timesPerWeek):
            guard Self.timesPerWeek.contains(timesPerWeek) else {
                throw CreateHabitErrorEnum.invalidTimesPerWeek
            }
        case .fixedDays(let weekdays):
            guard !weekdays.isEmpty else {
                throw CreateHabitErrorEnum.emptyWeekdays
            }
            guard weekdays.allSatisfy(Self.weekdays.contains) else {
                throw CreateHabitErrorEnum.invalidWeekdays
            }
        }
    }

    private static func isHexColor(_ value: String) -> Bool {
        value.count == 7
            && value.hasPrefix("#")
            && value.dropFirst().allSatisfy { $0.isASCII && $0.isHexDigit }
    }
}
