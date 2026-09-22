//
//  HabitReminderEntity.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import SwiftData
import Foundation

@Model
final class HabitReminderEntity {
    var habit: HabitEntity?
    var time: Date
    var enabled: Bool
    var isMutedOnWeekends: Bool

    init(
        time: Date,
        enabled: Bool,
        isMutedOnWeekends: Bool
    ) {
        self.time = time
        self.enabled = enabled
        self.isMutedOnWeekends = isMutedOnWeekends
    }
}
