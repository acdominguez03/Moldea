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
    
    let id: String
    let title: String
    var percentage: Int
    var kind: Kind = .day
    
    var color: String {
        switch kind {
        case .weekly:
            return "weekly"
        case .day:
            switch percentage {
            case ..<60:
                return "gray_500"
            case ..<80:
                return "gray_800"
            default:
                return "gray"
            }
        }
    }
}
