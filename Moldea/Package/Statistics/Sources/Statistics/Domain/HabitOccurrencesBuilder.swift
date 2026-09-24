//
//  HabitOccurrencesBuilder.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import Foundation
import Core

struct HabitOccurrencesBuilder {
    private static let bucketOffsets = [0, 7, 14, 21]

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func monthBuckets(containing date: Date) -> [DateInterval] {
        guard let month = calendar.dateInterval(of: .month, for: date) else {
            return []
        }
        let starts = Self.bucketOffsets.compactMap {
            calendar.date(byAdding: .day, value: $0, to: month.start)
        }
        return starts.enumerated().map { index, start in
            let end = index + 1 < starts.count ? starts[index + 1] : month.end
            return DateInterval(start: start, end: end)
        }
    }

    func monthStarts(ofYearContaining date: Date) -> [Date] {
        guard let year = calendar.dateInterval(of: .year, for: date) else {
            return []
        }
        return (0..<calendar.monthSymbols.count).compactMap {
            calendar.date(byAdding: .month, value: $0, to: year.start)
        }
    }

    func monthOccurrences(of habits: [TodayHabit], containing date: Date, until today: Date) -> [TodayHabit] {
        monthBuckets(containing: date).flatMap {
            occurrences(of: habits, in: $0, until: today)
        }
    }

    func occurrences(of habits: [TodayHabit], in bucket: DateInterval, until today: Date) -> [TodayHabit] {
        let lastDay = calendar.startOfDay(for: today)
        guard bucket.start <= lastDay else {
            return []
        }
        let days = days(in: bucket, until: lastDay)

        return habits.flatMap { todayHabit in
            let bucketCompletions = todayHabit.completions.filter {
                $0.day >= bucket.start && $0.day < bucket.end
            }

            if case .weeklyCount = todayHabit.habit.schedule.frequency {
                return [
                    TodayHabit(
                        habit: todayHabit.habit,
                        completions: bucketCompletions,
                        referenceDay: bucket.start,
                        calendar: calendar
                    )
                ]
            }

            let completionsByDay = Dictionary(grouping: bucketCompletions) {
                calendar.startOfDay(for: $0.day)
            }
            return days.compactMap { day in
                let weekday = calendar.component(.weekday, from: day)
                guard todayHabit.habit.schedule.frequency.isScheduled(on: weekday) else {
                    return nil
                }
                return TodayHabit(
                    habit: todayHabit.habit,
                    completions: completionsByDay[day] ?? [],
                    referenceDay: day,
                    calendar: calendar
                )
            }
        }
    }

    func lastDays(_ count: Int, until today: Date) -> [Date] {
        let lastDay = calendar.startOfDay(for: today)
        return (0..<max(count, 0)).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: lastDay)
        }
    }

    func occurrences(of habits: [TodayHabit], on day: Date) -> [TodayHabit] {
        let referenceDay = calendar.startOfDay(for: day)
        let weekday = calendar.component(.weekday, from: referenceDay)

        return habits.compactMap { todayHabit in
            guard todayHabit.habit.schedule.frequency.isScheduled(on: weekday) else {
                return nil
            }
            return TodayHabit(
                habit: todayHabit.habit,
                completions: todayHabit.completions.filter {
                    calendar.isDate($0.day, inSameDayAs: referenceDay)
                },
                referenceDay: referenceDay,
                calendar: calendar
            )
        }
    }

    private func days(in bucket: DateInterval, until lastDay: Date) -> [Date] {
        var days: [Date] = []
        var day = calendar.startOfDay(for: bucket.start)
        while day < bucket.end, day <= lastDay {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else {
                break
            }
            day = next
        }
        return days
    }
}
