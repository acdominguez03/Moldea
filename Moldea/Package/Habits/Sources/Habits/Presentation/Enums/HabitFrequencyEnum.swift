//
//  HabitFrequency.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import Foundation

enum HabitFrequencyEnum: String, CaseIterable, Identifiable {
    case everyDay
    case timesPerWeek
    case fixedDays
    
    var id: Self { self }
    
    var name: LocalizedStringResource {
        switch self {
        case .everyDay: HabitsTextsEnum.everyDayFrequency
        case .timesPerWeek: HabitsTextsEnum.timesPerWeekFrequency
        case .fixedDays: HabitsTextsEnum.fixedDaysFrequency
        }
    }
}
