//
//  HabitReminder.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Foundation

public struct HabitReminder: Sendable, Equatable {
    public let time: Date
    public let isEnabled: Bool
    public let isMutedOnWeekends: Bool

    public init(time: Date, isEnabled: Bool, isMutedOnWeekends: Bool) {
        self.time = time
        self.isEnabled = isEnabled
        self.isMutedOnWeekends = isMutedOnWeekends
    }
}
