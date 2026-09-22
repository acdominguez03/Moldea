//
//  CreateHabitError.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

enum CreateHabitError: Error, Equatable {
    case emptyName
    case invalidColor
    case invalidRepetitionsPerDay
    case invalidTimesPerWeek
    case emptyWeekdays
    case invalidWeekdays
}
