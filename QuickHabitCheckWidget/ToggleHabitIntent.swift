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
    static let title: LocalizedStringResource = "Toggle habit"

    @Parameter(title: "Habit")
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
        let getTodayHabits = DefaultGetTodayHabitsUseCase(
            repository: SwiftDataTodayHabitsRepository(modelContainer: container)
        )

        let todayHabits = try await getTodayHabits.execute(on: .now)
        guard let todayHabit = todayHabits.first(where: { $0.id == id }) else {
            return .result()
        }

        // Este intent corre en el proceso de la extensión, que no gestiona las notificaciones de la
        // app: la siguiente sincronización desde la app deja las pendientes al día.
        try await DefaultToggleHabitCompletionUseCase(
            repository: SwiftDataHabitRepository(modelContainer: container),
            notificationScheduler: NoOpHabitNotificationScheduler()
        ).execute(
            habitID: todayHabit.id,
            day: todayHabit.referenceDay,
            completedCount: todayHabit.completedToday,
            repetitionsPerDay: todayHabit.habit.schedule.repetitionsPerDay
        )

        let updatedHabits = try await getTodayHabits.execute(on: .now)
        let progress = CalculateHabitsProgressUseCase().execute(habits: updatedHabits, scope: .daily)
        UserDefaultsTodayProgressStore().save(fraction: progress.fraction, on: .now)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
