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
    /// Solo con `.weeklyCount`.
    var timesPerWeek: Int?
    /// Solo con `.fixedDays`. Valores de `Calendar.weekday` (1 = domingo ... 7 = sábado).
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
