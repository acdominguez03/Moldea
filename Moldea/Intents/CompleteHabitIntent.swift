//
//  CompleteHabitIntent.swift
//  Moldea
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import AppIntents
import Core
import WidgetKit

struct CompleteHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete a habit"
    static let description = IntentDescription("Marks one repetition of a habit scheduled for today as done.")

    static let openAppWhenRun = false

    @Parameter(title: "Habit", requestValueDialog: "Which habit did you complete?")
    var habit: HabitAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Complete \(\.$habit)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try MoldeaSchema.makeModelContainer()
        let getTodayHabits = DefaultGetTodayHabitsUseCase(
            repository: SwiftDataTodayHabitsRepository(modelContainer: container)
        )
        let name = habit.name

        let todayHabits = try await getTodayHabits.execute(on: .now)
        guard let todayHabit = todayHabits.first(where: { $0.id == habit.id }) else {
            throw NotScheduledTodayError(name: name)
        }

        let result = try await DefaultToggleHabitCompletionUseCase(
            repository: SwiftDataHabitRepository(modelContainer: container)
        ).execute(
            habitID: todayHabit.id,
            day: todayHabit.referenceDay,
            completedCount: todayHabit.completedToday,
            repetitionsPerDay: todayHabit.habit.schedule.repetitionsPerDay,
            mode: .addOnly
        )

        if case .alreadyCompleted = result {
            return .result(dialog: "You have already completed \(name) today.")
        }

        let updatedHabits = try await getTodayHabits.execute(on: .now)
        let progress = CalculateHabitsProgressUseCase().execute(habits: updatedHabits, scope: .daily)
        UserDefaultsTodayProgressStore().save(fraction: progress.fraction, on: .now)
        WidgetCenter.shared.reloadAllTimelines()

        switch result {
        case .progressed(let done, let total):
            return .result(dialog: "Done! \(name): \(done) of \(total) today.")
        case .completed, .alreadyCompleted, .reset:  // `.reset` no ocurre con `.addOnly`
            return .result(dialog: "Completed! \(name) is done for today.")
        }
    }
}

private struct NotScheduledTodayError: Error, CustomLocalizedStringResourceConvertible {
    let name: String

    var localizedStringResource: LocalizedStringResource {
        "\(name) is not scheduled for today."
    }
}
