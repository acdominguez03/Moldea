//
//  ChooseHabitIconViewModel.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class ChooseHabitIconViewModel {
    private(set) var families: [HabitIconFamily] = []

    private let catalog: any HabitIconCatalog
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Habits",
        category: "ChooseHabitIcon"
    )

    init(catalog: any HabitIconCatalog) {
        self.catalog = catalog
    }

    func load() async {
        do {
            families = try await catalog.loadFamilies()
        } catch {
            logger.error("Could not load the icon catalog: \(String(describing: error), privacy: .public)")
        }
    }

    func sections(matching query: String) -> [HabitIconFamily] {
        let terms = query.split(whereSeparator: \.isWhitespace)
        guard !terms.isEmpty else { return families }

        return families.compactMap { family in
            let symbols = family.symbols.filter { symbol in
                terms.allSatisfy { symbol.localizedStandardContains($0) }
            }
            return symbols.isEmpty ? nil : HabitIconFamily(key: family.key, symbols: symbols)
        }
    }
}
