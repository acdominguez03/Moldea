//
//  GenerableHabitCommand.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

import FoundationModels

@Generable
enum GenerableCommandIntent {
    case create
    case delete
    case listCompleted
}

@Generable
struct GenerableCommandDecision {
    var reasoning: String

    @Guide(description: "El comando, y nada más")
    var command: GenerableCommandIntent
}

@Generable
enum GenerableFrequencyKind {
    case daily
    case timesPerWeek
    case fixedWeekdays
}

@Generable
enum GenerableWeekday {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
}

@Generable
struct GenerableHabitDraft {
    @Guide(description: "Nombre corto del hábito, sin cantidades")
    var name: String

    var frequency: GenerableFrequencyKind

    @Guide(description: "Veces por semana, de 1 a 7", .range(1...7))
    var timesPerWeek: Int

    @Guide(description: "Días de la semana que menciona la frase", .minimumCount(1))
    var weekdays: [GenerableWeekday]

    @Guide(description: "Veces al día", .range(1...20))
    var repetitionsPerDay: Int
}
