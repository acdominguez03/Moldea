//
//  ToggleHabitIntent.swift
//  QuickHabitCheckWidget
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import AppIntents
import WidgetKit
import Core

struct ToggleHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Marcar hábito"

    @Parameter(title: "Hábito")
    var habitID: String

    init() {}

    init(habitID: UUID) {
        self.habitID = habitID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: habitID) else {
            return .result()
        }

        let container = try MoldeaSchema.makeModelContainer()
        let getTodayHabitsUseCase = DefaultGetTodayHabitsUseCase(
            repository: SwiftDataTodayHabitsRepository(modelContainer: container)
        )
        let useCase = DefaultToggleTodayHabitUseCase(
            getTodayHabitsUseCase: getTodayHabitsUseCase,
            toggleHabitCompletionUseCase: DefaultToggleHabitCompletionUseCase(
                repository: SwiftDataHabitRepository(modelContainer: container)
            ),
            calculateHabitsProgressUseCase: CalculateHabitsProgressUseCase(),
            todayProgressStore: UserDefaultsTodayProgressStore()
        )

        try await useCase.execute(habitID: id, on: .now)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
