//
//  HabitCommandErrorEnum.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

enum HabitCommandErrorEnum: Error, Equatable {
    case notUnderstood
    case habitNotFound
    case missingFrequencyData
    case schemaFailed
}
