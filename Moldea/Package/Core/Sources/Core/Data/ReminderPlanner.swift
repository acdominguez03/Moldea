//
//  ReminderPlanner.swift
//  Core
//

import Foundation

struct PlannedReminder: Equatable, Sendable {
    enum KindEnum: Equatable, Sendable {
        case habit(Habit.ID)
        case summary
    }

    let kind: KindEnum
    let identifier: String
    let fireDate: Date

    /// `nil` para el aviso de la noche, que no pertenece a ningún hábito.
    var habitID: Habit.ID? {
        if case .habit(let id) = kind { id } else { nil }
    }
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

    /// Como los de los hábitos, empieza por `identifierPrefix`: la limpieza por prefijo y
    /// `cancelAllReminders` también lo cubren.
    static func summaryIdentifier(day: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        return String(
            format: "%@summary-%04d%02d%02d",
            identifierPrefix,
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

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
    /// - Parameter includesDailySummary: añade el aviso de la noche (`DailySummaryReminder`).
    static func plan(
        candidates: [ReminderCandidate],
        now: Date,
        calendar: Calendar,
        budget: Int,
        includesDailySummary: Bool = false,
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
                        kind: .habit(habit.id),
                        identifier: identifier(habitID: habit.id, day: day, calendar: calendar),
                        fireDate: fireDate
                    )
                )
            }
        }

        if includesDailySummary {
            planned += dailySummaries(
                candidates: candidates,
                now: now,
                calendar: calendar,
                horizonDays: horizonDays
            )
        }

        planned.sort { ($0.fireDate, $0.identifier) < ($1.fireDate, $1.identifier) }
        return Array(planned.prefix(max(budget, 0)))
    }

    // MARK: Aviso de la noche

    /// Hábitos activos que tocan en `weekday`. Igual que la pestaña Diario de Today: los de "X
    /// veces por semana" no tienen día concreto y no cuentan. El aviso propio de cada hábito no
    /// influye: el resumen es independiente.
    private static func scheduledHabits(
        in candidates: [ReminderCandidate],
        weekday: Int
    ) -> [ReminderCandidate] {
        candidates.filter {
            $0.habit.isActive && $0.habit.schedule.frequency.isScheduled(on: weekday)
        }
    }

    /// Hoy toca al menos un hábito y todos están completados. Con esto el aviso de hoy no procede,
    /// y si ya salió, hay que limpiarlo del Centro de Notificaciones.
    static func isEverythingCompletedToday(
        candidates: [ReminderCandidate],
        now: Date,
        calendar: Calendar
    ) -> Bool {
        let today = scheduledHabits(in: candidates, weekday: calendar.component(.weekday, from: now))
        return !today.isEmpty && today.allSatisfy(\.isCompletedToday)
    }

    /// Un aviso por día que tenga hábitos programados. Hoy solo si queda alguno por completar y la
    /// hora no ha pasado. El texto es fijo, así que para los días siguientes basta con saber si
    /// tocan hábitos; lo demás se corrige con cada sincronización.
    private static func dailySummaries(
        candidates: [ReminderCandidate],
        now: Date,
        calendar: Calendar,
        horizonDays: Int
    ) -> [PlannedReminder] {
        let today = calendar.startOfDay(for: now)
        var summaries: [PlannedReminder] = []

        for offset in 0..<horizonDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }

            let scheduled = scheduledHabits(in: candidates, weekday: calendar.component(.weekday, from: day))
            guard !scheduled.isEmpty else { continue }
            if offset == 0 && scheduled.allSatisfy(\.isCompletedToday) { continue }

            guard let fireDate = calendar.date(
                bySettingHour: DailySummaryReminder.hour,
                minute: DailySummaryReminder.minute,
                second: 0,
                of: day
            ), fireDate > now
            else { continue }

            summaries.append(
                PlannedReminder(
                    kind: .summary,
                    identifier: summaryIdentifier(day: day, calendar: calendar),
                    fireDate: fireDate
                )
            )
        }
        return summaries
    }
}
