//
//  HabitAppEntity.swift
//  Moldea
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import AppIntents
import Core

struct HabitAppEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
    static let defaultQuery = HabitEntityQuery()

    let id: UUID

    @Property(title: "Name")
    var name: String

    let icon: String

    init(habit: Habit) {
        self.id = habit.id
        self.icon = habit.icon
        self.name = habit.name
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: icon))
    }
}

struct HabitEntityQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [HabitAppEntity] {
        try await todayEntities().filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [HabitAppEntity] {
        try await todayEntities().filter { $0.name.localizedStandardContains(string) }
    }

    func suggestedEntities() async throws -> [HabitAppEntity] {
        try await todayEntities()
    }

    private func todayEntities() async throws -> [HabitAppEntity] {
        let container = try MoldeaSchema.makeModelContainer()
        let useCase = DefaultGetTodayHabitsUseCase(
            repository: SwiftDataTodayHabitsRepository(modelContainer: container)
        )
        return try await useCase.execute(on: .now).map { HabitAppEntity(habit: $0.habit) }
    }
}
