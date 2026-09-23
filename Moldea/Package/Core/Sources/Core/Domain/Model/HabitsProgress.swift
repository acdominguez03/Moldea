//
//  HabitsProgress.swift
//  Core
//
//  Created by Andrés on 23/09/2026.
//

public struct HabitsProgress: Sendable, Equatable {
    public let completedHabits: Int
    public let totalHabits: Int
    public let completedUnits: Int
    public let totalUnits: Int
    
    public init(completedHabits: Int, totalHabits: Int, completedUnits: Int, totalUnits: Int) {
        self.completedHabits = completedHabits
        self.totalHabits = totalHabits
        self.completedUnits = completedUnits
        self.totalUnits = totalUnits
    }
    
    public var fraction: Double {
        guard totalUnits > 0 else {
            return 0
        }
        return Double(completedUnits) / Double(totalUnits)
    }
    
    public var percentage: Int {
        Int((fraction * 100).rounded())
    }
}
