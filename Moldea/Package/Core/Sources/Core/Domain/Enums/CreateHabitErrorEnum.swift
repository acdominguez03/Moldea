//
//  CreateHabitError.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

public enum CreateHabitErrorEnum: Error, Equatable {
    case emptyName
    case invalidColor
    case invalidRepetitionsPerDay
    case invalidTimesPerWeek
    case emptyWeekdays
    case invalidWeekdays
}
