//
//  ReminderPlanner.swift
//  Core
//

import Foundation

struct PlannedReminder: Equatable, Sendable {
    let habitID: Habit.ID
    let identifier: String
    let fireDate: Date
}

/// Decide qué notificaciones tendría que haber pendientes. No toca `UserNotifications`, así que
/// se puede probar entera.
///
/// Modelo: una notificación **puntual por hábito y día**, no repetitivos. Un repetitivo no puede
/// saltarse una sola ocurrencia, y completar un hábito tiene que quitar solo la de hoy.
enum ReminderPlanner {
    static let identifierPrefix = "habit-reminder-"

    /// Días hacia delante que se planifican como máximo. El límite real lo pone el presupuesto.
    static let maxHorizonDays = 28

    static func identifier(habitID: Habit.ID, day: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        return String(
            format: "%@%@-%04d%02d%02d",
            identifierPrefix,
            habitID.uuidString,
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    /// - Parameter budget: máximo de peticiones que se pueden dejar pendientes. Se reparte por
    ///   fecha: se conservan las `budget` más próximas de todos los hábitos, así que todos tienen
    ///   el mismo horizonte.
    static func plan(
        candidates: [ReminderCandidate],
        now: Date,
        calendar: Calendar,
        budget: Int,
        horizonDays: Int = maxHorizonDays
    ) -> [PlannedReminder] {
        let today = calendar.startOfDay(for: now)
        var planned: [PlannedReminder] = []

        for candidate in candidates {
            let habit = candidate.habit
            guard habit.isActive, let reminder = habit.reminder, reminder.isEnabled else { continue }

            let weekdays = HabitReminderMessageBuilder.weekdays(
                frequency: habit.schedule.frequency,
                isMutedOnWeekends: reminder.isMutedOnWeekends
            )
            guard !weekdays.isEmpty else { continue }

            let time = calendar.dateComponents([.hour, .minute], from: reminder.time)

            for offset in 0..<horizonDays {
                guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                      weekdays.contains(calendar.component(.weekday, from: day))
                else { continue }

                // Completado hoy: no hace falta avisar. Si se deshace, la siguiente sincronización
                // la vuelve a planificar.
                if offset == 0 && candidate.isCompletedToday { continue }

                guard let fireDate = calendar.date(
                    bySettingHour: time.hour ?? 0,
                    minute: time.minute ?? 0,
                    second: 0,
                    of: day
                ), fireDate > now
                else { continue }

                planned.append(
                    PlannedReminder(
                        habitID: habit.id,
                        identifier: identifier(habitID: habit.id, day: day, calendar: calendar),
                        fireDate: fireDate
                    )
                )
            }
        }

        planned.sort { ($0.fireDate, $0.identifier) < ($1.fireDate, $1.identifier) }
        return Array(planned.prefix(max(budget, 0)))
    }
}
