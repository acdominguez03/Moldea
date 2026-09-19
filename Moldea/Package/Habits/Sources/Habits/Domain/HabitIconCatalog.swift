//
//  HabitIconCatalog.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

protocol HabitIconCatalog: Sendable {
    func loadFamilies() async throws -> [HabitIconFamily]
}
