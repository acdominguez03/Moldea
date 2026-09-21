//
//  HabitFrequency.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

/// Con qué frecuencia se repite un hábito. Cada caso lleva solo los datos que le aplican.
public enum HabitFrequency: Sendable, Equatable {
    case daily
    case weeklyCount(timesPerWeek: Int)
    /// Valores de `Calendar.weekday` (1 = domingo ... 7 = sábado).
    case fixedDays(weekdays: Set<Int>)
}
