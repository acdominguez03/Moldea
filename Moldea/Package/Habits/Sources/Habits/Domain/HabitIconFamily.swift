//
//  HabitIconFamily.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

struct HabitIconFamily: Identifiable, Hashable, Sendable {
    let key: String
    let symbols: [String]
    var id: String { key }
}
