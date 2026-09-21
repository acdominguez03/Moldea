//
//  CreateHabitUseCase.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Foundation
import Core

protocol CreateHabitUseCase: Sendable {
    func execute(
        name: String,
        color: String,
        icon: String,
        frequency: HabitFrequency,
        repetitionsPerDay: Int
    ) async throws
}

struct DefaultCreateHabitUseCase: CreateHabitUseCase {
    private static let weekdays = 1...7
    private static let timesPerWeek = 1...7

    private let repository: any HabitRepository
    private let makeID: @Sendable () -> UUID
    private let now: @Sendable () -> Date

    init(
        repository: any HabitRepository,
        makeID: @escaping @Sendable () -> UUID = { UUID() },
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repository = repository
        self.makeID = makeID
        self.now = now
    }

    func execute(
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
            throw CreateHabitError.emptyName
        }
        guard Self.isHexColor(color) else {
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
