//
//  SwiftDataTodayHabitsRepository.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import SwiftData
import Foundation

@ModelActor
public actor SwiftDataTodayHabitsRepository: TodayHabitsRepository {
    public func fetchTodayHabits(on day: Date) throws -> [TodayHabit] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let weekday = calendar.component(.weekday, from: day)

        let habits = try modelContext.fetch(
            FetchDescriptor<HabitEntity>(sortBy: [SortDescriptor(\.name)])
        )
        let completions = try modelContext.fetch(
            FetchDescriptor<HabitCompletionEntity>(
                predicate: #Predicate { $0.day >= start && $0.day < end }
            )
        )

        return ScheduledHabitsBuilder.habits(
            from: habits,
            with: completions,
            referenceDay: start
        ) { frequency in
            ScheduledHabitsBuilder.isScheduled(frequency, on: weekday)
        }
    }
}
