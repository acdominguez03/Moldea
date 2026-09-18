//
//  MainTab.swift
//  Navigation
//
//  Created by Andrés on 18/09/2026.
//

import Foundation
import Core

public enum MainTab: Hashable, CaseIterable {
    case today
    case statistics
    case habits
    case settings
    
    case microphone
    
    var icon: String {
        switch self {
        case .today:
            return "calendar"
        case .statistics:
            return "chart.bar"
        case .habits:
            return "checklist"
        case .settings:
            return "gearshape"
        case .microphone:
            return "microphone"
        }
    }
    
    public var description: LocalizedStringResource {
        switch self {
        case .today:
            return CoreTextsEnum.todayTitle
        case .statistics:
            return CoreTextsEnum.statisticsTitle
        case .habits:
            return CoreTextsEnum.habitsTitle
        case .settings:
            return CoreTextsEnum.settingsTitle
        case .microphone:
            return CoreTextsEnum.voiceInputButton
        }
    }
}
