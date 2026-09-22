//
//  HabitSchedule.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

public struct HabitSchedule: Sendable, Equatable {
    public let frequency: HabitFrequency
    public let repetitionsPerDay: Int

    public init(frequency: HabitFrequency, repetitionsPerDay: Int) {
        self.frequency = frequency
        self.repetitionsPerDay = repetitionsPerDay
    }
}
