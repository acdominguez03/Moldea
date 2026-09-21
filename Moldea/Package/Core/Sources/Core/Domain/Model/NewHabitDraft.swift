//
//  NewHabitDraft.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

public struct NewHabitDraft: Sendable, Equatable {
    public let name: String
    public let frequency: HabitFrequency
    public let repetitionsPerDay: Int

    public init(name: String, frequency: HabitFrequency, repetitionsPerDay: Int) {
        self.name = name
        self.frequency = frequency
        self.repetitionsPerDay = repetitionsPerDay
    }
}
