//
//  HabitStatistic.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import Foundation

struct HabitStatistic: Identifiable {
    enum Kind {
        case day
        case weekly
    }

    enum Tier: String {
        case low
        case medium
        case high
        case weekly
    }

    let id: String
    let title: String
    let accessibilityTitle: String
    var percentage: Int
    var kind: Kind = .day
    var interval: DateInterval?

    var tier: Tier {
        switch kind {
        case .weekly:
            return .weekly
        case .day:
            switch percentage {
            case ..<60:
                return .low
            case ..<80:
                return .medium
            default:
                return .high
            }
        }
    }
}
