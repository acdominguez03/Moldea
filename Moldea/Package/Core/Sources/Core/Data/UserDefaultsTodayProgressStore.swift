//
//  UserDefaultsTodayProgressStore.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import Foundation

public struct UserDefaultsTodayProgressStore: TodayProgressStore {
    private enum Key {
        static let fraction = "todayProgress.fraction"
        static let day = "todayProgress.day"
    }

    private let suiteName: String
    private let calendar: Calendar

    public init(
        suiteName: String = AppGroup.identifier,
        calendar: Calendar = .current
    ) {
        self.suiteName = suiteName
        self.calendar = calendar
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    public func save(fraction: Double, on day: Date) {
        defaults.set(fraction, forKey: Key.fraction)
        defaults.set(calendar.startOfDay(for: day), forKey: Key.day)
    }

    public func fraction(on day: Date) -> Double {
        guard let savedDay = defaults.object(forKey: Key.day) as? Date,
              calendar.isDate(savedDay, inSameDayAs: day) else {
            return 0
        }
        return defaults.double(forKey: Key.fraction)
    }
}
