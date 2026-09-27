//
//  Habit.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Foundation

public struct Habit: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let color: String
    public let icon: String
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date
    public let schedule: HabitSchedule
    public let reminder: HabitReminder?
    public let inactivePeriods: [HabitInactivePeriod]

    public init(
        id: UUID,
        name: String,
        color: String,
        icon: String,
        isActive: Bool,
        createdAt: Date,
        updatedAt: Date,
        schedule: HabitSchedule,
        reminder: HabitReminder? = nil,
        inactivePeriods: [HabitInactivePeriod] = []
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.schedule = schedule
        self.reminder = reminder
        self.inactivePeriods = inactivePeriods
    }
}

public extension Habit {
    var hasActiveReminder: Bool {
        reminder?.isEnabled ?? false
    }

    func isActive(on day: Date, calendar: Calendar = .current) -> Bool {
        !effectiveInactivePeriods.contains { $0.contains(day: day, calendar: calendar) }
    }

    func activeDays(in interval: DateInterval, calendar: Calendar = .current) -> Int {
        var count = 0
        var day = calendar.startOfDay(for: interval.start)
        while day < interval.end {
            if isActive(on: day, calendar: calendar) {
                count += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else {
                break
            }
            day = next
        }
        return count
    }

    private var effectiveInactivePeriods: [HabitInactivePeriod] {
        guard !isActive, !inactivePeriods.contains(where: \.isOpen) else {
            return inactivePeriods
        }
        return inactivePeriods + [HabitInactivePeriod(start: updatedAt)]
    }
}
