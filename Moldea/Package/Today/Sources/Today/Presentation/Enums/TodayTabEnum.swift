//
//  TodayTabEnum.swift
//  Today
//
//  Created by Andrés on 23/09/2026.
//

import Foundation

enum TodayTabEnum: CaseIterable, Hashable {
    case daily
    case weekly

    var title: LocalizedStringResource {
        switch self {
        case .daily:
            TodayTextsEnum.tabDaily
        case .weekly:
            TodayTextsEnum.tabWeekly
        }
    }
}
