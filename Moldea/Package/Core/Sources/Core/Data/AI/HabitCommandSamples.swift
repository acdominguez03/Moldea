//
//  HabitCommandSamples.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

#if DEBUG
import Foundation

enum HabitCommandKindEnum: Sendable, Equatable, CaseIterable {
    case create
    case delete
    case complete
}

extension HabitCommandEnum {
    var kind: HabitCommandKindEnum {
        switch self {
        case .create: .create
        case .delete: .delete
        case .complete: .complete
        }
    }
}

struct HabitCommandSample: Sendable, CustomStringConvertible {
    let phrase: String
    let expected: HabitCommandKindEnum

    var description: String { phrase }
}

enum HabitCommandSamples {
    static let all: [HabitCommandSample] = [
        .init(phrase: "quiero crear un hábito de leer todos los días", expected: .create),
        .init(phrase: "añade nadar tres veces por semana", expected: .create),
        .init(phrase: "quiero empezar a meditar los lunes y los viernes", expected: .create),
        .init(phrase: "crea el hábito de leer la biblia los lunes y los miércoles", expected: .create),
        .init(phrase: "quiero estirar dos veces al día", expected: .create),
        .init(phrase: "borra el hábito de correr", expected: .delete),
        .init(phrase: "quita el hábito de leer", expected: .delete),
        .init(phrase: "ya no quiero beber agua", expected: .delete),
        .init(phrase: "hoy he bebido dos litros de agua", expected: .complete),
        .init(
            phrase: "he bebido dos litros de agua, he caminado veinte minutos y he salido a correr media hora",
            expected: .complete
        ),
        .init(phrase: "hoy no he corrido", expected: .complete),
        .init(phrase: "marca leer como hecho", expected: .complete),
        .init(phrase: "I want to create a habit of reading every day", expected: .create),
        .init(phrase: "delete the running habit", expected: .delete),
        .init(phrase: "I drank two litres of water today", expected: .complete),
    ]

    static let rotationKey = "com.moldea.debug.habitCommandSampleIndex"

    static func nextPhrase(defaults: UserDefaults = .standard) -> String {
        guard !all.isEmpty else { return "" }

        let index = defaults.integer(forKey: rotationKey) % all.count
        defaults.set((index + 1) % all.count, forKey: rotationKey)
        return all[index].phrase
    }
}
#endif
