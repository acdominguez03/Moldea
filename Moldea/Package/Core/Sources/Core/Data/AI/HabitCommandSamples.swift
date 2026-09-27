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
        .init(phrase: "añade tocar el piano todos los días", expected: .create),
        .init(phrase: "añade nadar tres veces por semana", expected: .create),
        .init(phrase: "crea el hábito de leer la biblia los lunes y los miércoles", expected: .create),

        .init(phrase: "hoy he bebido dos litros de agua", expected: .complete),
        .init(phrase: "he tocado el piano pero no he dormido bien", expected: .complete),
        .init(phrase: "hoy he tocado la guitarra", expected: .complete),

        .init(phrase: "borra el hábito de tocar el piano", expected: .delete),
        .init(phrase: "quita el de nadar", expected: .delete),
        .init(phrase: "elimina el hábito de tocar la guitarra", expected: .delete),
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
