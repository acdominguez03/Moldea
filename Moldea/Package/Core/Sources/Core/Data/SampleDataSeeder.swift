//
//  SampleDataSeeder.swift
//  Core
//
//  Created by Andrés on 24/09/2026.
//

import Foundation
import SwiftData

@MainActor
public enum SampleDataSeeder {
    private struct Sample {
        let name: String
        let color: String
        let icon: String
        let frequency: HabitFrequency
        let repetitionsPerDay: Int
        let currentWeek: [Int]
        let history: (_ monthOffset: Int, _ day: Int, _ weekday: Int) -> Int
    }

    private static let monday = 2
    private static let wednesday = 4
    private static let thursday = 5
    private static let sunday = 1

    private static let samples: [Sample] = [
        Sample(
            name: "Beber agua",
            color: "#3A6BC6",
            icon: "drop.fill",
            frequency: .daily,
            repetitionsPerDay: 3,
            currentWeek: [3, 2, 2, 3],
            history: { monthOffset, day, _ in
                switch monthOffset {
                case -2: 3
                case -1: 2
                default: day.isMultiple(of: 2) ? 3 : 2
                }
            }
        ),
        Sample(
            name: "Leer 20 minutos",
            color: "#8A6A4F",
            icon: "book.fill",
            frequency: .daily,
            repetitionsPerDay: 1,
            currentWeek: [1, 1, 1, 1],
            history: { monthOffset, day, _ in
                switch monthOffset {
                case -2: day.isMultiple(of: 5) ? 0 : 1
                case -1: day.isMultiple(of: 2) ? 1 : 0
                default: day.isMultiple(of: 4) ? 0 : 1
                }
            }
        ),
        Sample(
            name: "Entrenar",
            color: "#C8372D",
            icon: "figure.run",
            frequency: .fixedDays(weekdays: [2, 3, 4, 5]),
            repetitionsPerDay: 1,
            currentWeek: [1, 1, 0, 1],
            history: { monthOffset, _, weekday in
                switch monthOffset {
                case -2: 1
                case -1: weekday == monday || weekday == wednesday ? 1 : 0
                default: weekday == thursday ? 0 : 1
                }
            }
        ),
        Sample(
            name: "Meditar",
            color: "#6C5BC4",
            icon: "brain.head.profile",
            frequency: .fixedDays(weekdays: [2, 3, 4, 5]),
            repetitionsPerDay: 2,
            currentWeek: [1, 1, 1, 2],
            history: { monthOffset, _, _ in
                monthOffset == -1 ? 1 : 2
            }
        ),
        Sample(
            name: "Llamar a casa",
            color: "#2E8F83",
            icon: "phone.fill",
            frequency: .weeklyCount(timesPerWeek: 2),
            repetitionsPerDay: 1,
            currentWeek: [0, 0, 1, 0],
            history: { monthOffset, _, weekday in
                switch monthOffset {
                case -2: weekday == sunday || weekday == wednesday ? 1 : 0
                case -1: weekday == sunday ? 1 : 0
                default: weekday == wednesday ? 1 : 0
                }
            }
        )
    ]

    public static func seed(
        in container: ModelContainer,
        reference date: Date = .now,
        calendar: Calendar = .current
    ) throws {
        try seed(in: container.mainContext, reference: date, calendar: calendar)
    }

    public static func seed(
        in context: ModelContext,
        reference date: Date = .now,
        calendar: Calendar = .current
    ) throws {
        let today = calendar.startOfDay(for: date)
        let currentWeek = mondayToThursday(of: today, calendar: calendar)

        guard
            let currentMonth = calendar.dateInterval(of: .month, for: today),
            let firstDay = calendar.date(byAdding: .month, value: -2, to: currentMonth.start)
        else { return }

        let days = days(from: firstDay, through: today, calendar: calendar)

        for sample in samples {
            let habit = HabitEntity(
                id: UUID(),
                name: sample.name,
                color: sample.color,
                icon: sample.icon,
                active: true,
                createdAt: firstDay,
                updatedAt: date
            )
            HabitMapper.apply(
                HabitSchedule(
                    frequency: sample.frequency,
                    repetitionsPerDay: sample.repetitionsPerDay
                ),
                to: habit
            )
            context.insert(habit)

            for day in days {
                let planned = plannedRepetitions(
                    of: sample,
                    on: day,
                    currentWeek: currentWeek,
                    currentMonth: currentMonth.start,
                    calendar: calendar
                )
                let count = min(max(planned, 0), sample.repetitionsPerDay)

                for repetitionIndex in 0..<count {
                    context.insert(
                        HabitCompletionEntity(
                            id: UUID(),
                            habit: habit,
                            day: day,
                            repetitionIndex: repetitionIndex,
                            completedAt: calendar.date(
                                byAdding: .hour,
                                value: 8 + repetitionIndex * 4,
                                to: day
                            ) ?? day
                        )
                    )
                }
            }
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private static func plannedRepetitions(
        of sample: Sample,
        on day: Date,
        currentWeek: [Date],
        currentMonth: Date,
        calendar: Calendar
    ) -> Int {
        let weekday = calendar.component(.weekday, from: day)

        switch sample.frequency {
        case .weeklyCount:
            break
        case .daily, .fixedDays:
            guard sample.frequency.isScheduled(on: weekday) else {
                return 0
            }
        }

        if let index = currentWeek.firstIndex(of: day) {
            return sample.currentWeek.indices.contains(index) ? sample.currentWeek[index] : 0
        }

        let monthOffset = calendar.dateComponents(
            [.month],
            from: currentMonth,
            to: calendar.dateInterval(of: .month, for: day)?.start ?? currentMonth
        ).month ?? 0

        return sample.history(monthOffset, calendar.component(.day, from: day), weekday)
    }

    private static func days(from start: Date, through end: Date, calendar: Calendar) -> [Date] {
        var days: [Date] = []
        var day = start
        while day <= end {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }

    private static func mondayToThursday(of date: Date, calendar: Calendar) -> [Date] {
        let today = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7

        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) else {
            return []
        }
        return (0..<4).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }
}
