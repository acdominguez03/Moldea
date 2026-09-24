//
//  StatisticsDay.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import Foundation

struct StatisticsDay: Identifiable, Equatable {
    let date: Date
    let letter: String
    let number: Int

    var id: Date { date }
}
