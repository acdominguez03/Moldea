//
//  SwiftDataReminderPlanSource.swift
//  Core
//

import SwiftData
import Foundation

@ModelActor
public actor SwiftDataReminderPlanSource: ReminderPlanSource {
    public func fetchCandidates(on day: Date) throws -> [ReminderCandidate] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start

        let habits = try modelContext.fetch(FetchDescriptor<HabitEntity>())
        let completions = try modelContext.fetch(
            FetchDescriptor<HabitCompletionEntity>(
                predicate: #Predicate { $0.day >= start && $0.day < end }
            )
        )

        return ScheduledHabitsBuilder.habits(
            from: habits,
            with: completions,
            referenceDay: start
        ) { _ in true }
            .map { ReminderCandidate(habit: $0.habit, isCompletedToday: $0.isCompletedToday) }
    }
}
