//
//  HabitInactivePeriod.swift
//  Core
//
//  Created by Andrés on 27/09/2026.
//

import Foundation

public struct HabitInactivePeriod: Sendable, Equatable, Codable {
    public let start: Date
    public let end: Date?

    public init(start: Date, end: Date? = nil) {
        self.start = start
        self.end = end
    }

    public var isOpen: Bool {
        end == nil
    }

    func contains(day: Date, calendar: Calendar) -> Bool {
        let day = calendar.startOfDay(for: day)
        guard calendar.startOfDay(for: start) <= day else {
            return false
        }
        guard let end else {
            return true
        }
        return day < calendar.startOfDay(for: end)
    }
}
