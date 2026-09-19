//
//  BundleHabitIconCatalog.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import Foundation

struct BundleHabitIconCatalog: HabitIconCatalog {
    enum CatalogError: Error {
        case resourceNotFound
    }

    func loadFamilies() async throws -> [HabitIconFamily] {
        try await Self.readFamilies()
    }

    @concurrent
    private static func readFamilies() async throws -> [HabitIconFamily] {
        guard let url = Bundle.module.url(forResource: "habit-icon-families", withExtension: "json") else {
            throw CatalogError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        let catalog = try JSONDecoder().decode(CatalogDTO.self, from: data)
        return catalog.families.map { HabitIconFamily(key: $0.key, symbols: $0.symbols) }
    }
}

private struct CatalogDTO: Decodable {
    let families: [FamilyDTO]
}

private struct FamilyDTO: Decodable {
    let key: String
    let symbols: [String]
}
