//
//  CreateHabitUseCase.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Foundation

public protocol CreateHabitUseCase: Sendable {
    func execute(
        name: String,
        color: String,
        icon: String,
        frequency: HabitFrequency,
        repetitionsPerDay: Int
    ) async throws
}

public struct DefaultCreateHabitUseCase: CreateHabitUseCase {
    private static let weekdays = 1...7
    private static let timesPerWeek = 1...7

    private let repository: any HabitRepository
    private let makeID: @Sendable () -> UUID
    private let now: @Sendable () -> Date

    public init(
        repository: any HabitRepository,
        makeID: @escaping @Sendable () -> UUID = { UUID() },
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repository = repository
        self.makeID = makeID
        self.now = now
    }

    public func execute(
        name: String,
        color: String,
        icon: String,
        frequency: HabitFrequency,
        repetitionsPerDay: Int
    ) async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate(
            trimmedName: trimmedName,
            color: color,
            frequency: frequency,
            repetitionsPerDay: repetitionsPerDay
        )

        let date = now()
        let habit = Habit(
            id: makeID(),
            name: trimmedName,
            color: color,
            icon: icon,
            isActive: true,
            createdAt: date,
            updatedAt: date,
            schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: repetitionsPerDay)
        )
        try await repository.create(habit)
    }

    private func validate(
        trimmedName: String,
        color: String,
        frequency: HabitFrequency,
        repetitionsPerDay: Int
    ) throws {
        guard !trimmedName.isEmpty else {
            throw CreateHabitErrorEnum.emptyName
        }
        guard Self.isHexColor(color) else {
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
