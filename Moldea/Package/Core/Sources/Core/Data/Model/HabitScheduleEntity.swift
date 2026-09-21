//
//  HabitScheduleEntity.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import SwiftData

@Model
final class HabitScheduleEntity {
    var habit: HabitEntity?
    var frequencyType: FrequencyType
    var timesPerWeek: Int?
    var fixedWeekdays: [Int]?
    var repetitionsPerDay: Int

    init(
        frequencyType: FrequencyType,
        timesPerWeek: Int? = nil,
        fixedWeekdays: [Int]? = nil,
        repetitionsPerDay: Int = 1
    ) {
        self.frequencyType = frequencyType
        self.timesPerWeek = timesPerWeek
        self.fixedWeekdays = fixedWeekdays
        self.repetitionsPerDay = repetitionsPerDay
    }
}
