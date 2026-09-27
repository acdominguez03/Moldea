//
//  DebugHistorySeeder.swift
//  Core
//

#if DEBUG
import Foundation
import SwiftData

/// Siembra más de un año de historial en SwiftData para ver las gráficas con datos reales. Solo
/// existe en DEBUG.
///
/// - Se ejecuta **una sola vez** por instalación (marca en `UserDefaults`) y solo si no hay ningún
///   hábito, así que nunca toca datos que ya tengas. Las siguientes ejecuciones cuestan una lectura
///   de `UserDefaults`.
/// - Corre en su propio contexto (`@ModelActor`), fuera del hilo principal, y guarda una sola vez.
/// - Es determinista: el mismo generador con la misma semilla, así que las gráficas salen igual
///   cada vez que se reinstala.
/// - Los hábitos no llevan recordatorio, para no programar notificaciones.
///
/// Para volver a sembrar: borra la app o pon `debug.yearHistorySeeded` a `false` y elimina los
/// hábitos.
@ModelActor
public actor DebugHistorySeeder {
    public static let seededKey = "debug.yearHistorySeeded"

    /// Meses completos anteriores al actual que cubre el historial.
    static let monthsBack = 12

    private struct Profile: Sendable {
        let name: String
        let color: String
        let icon: String
        let frequency: HabitFrequency
        let repetitionsPerDay: Int
        let isActive: Bool
        /// Días antes de hoy en los que termina el historial: un hábito en pausa dejó de registrarse.
        let endsDaysAgo: Int
        let seed: UInt64
        /// Probabilidad (0...1) de completar un día programado según cuánto ha avanzado el año
        /// (`progress`: 0 al principio, 1 hoy), el mes (1...12) y el día de la semana.
        let chance: @Sendable (_ progress: Double, _ month: Int, _ weekday: Int) -> Double
    }

    private static let profiles: [Profile] = [
        // Constante y alto: la línea base.
        Profile(
            name: "Beber agua", color: "#3A6BC6", icon: "drop.fill",
            frequency: .daily, repetitionsPerDay: 4, isActive: true, endsDaysAgo: 0, seed: 1,
            chance: { _, _, weekday in weekday == 1 || weekday == 7 ? 0.75 : 0.9 }
        ),
        // Mejora durante el año: 35 % al principio, 90 % ahora.
        Profile(
            name: "Leer 20 minutos", color: "#8A6A4F", icon: "book.fill",
            frequency: .daily, repetitionsPerDay: 1, isActive: true, endsDaysAgo: 0, seed: 2,
            chance: { progress, _, _ in 0.35 + 0.55 * progress }
        ),
        // Estacional: cae en julio y agosto.
        Profile(
            name: "Entrenar", color: "#C8372D", icon: "figure.run",
            frequency: .fixedDays(weekdays: [2, 4, 6]), repetitionsPerDay: 1,
            isActive: true, endsDaysAgo: 0, seed: 3,
            chance: { _, month, _ in month == 7 || month == 8 ? 0.35 : 0.8 }
        ),
        // Empieza fuerte y se va abandonando.
        Profile(
            name: "Meditar", color: "#6C5BC4", icon: "brain.head.profile",
            frequency: .daily, repetitionsPerDay: 2, isActive: true, endsDaysAgo: 0, seed: 4,
            chance: { progress, _, _ in 0.92 - 0.65 * progress }
        ),
        // Con varias repeticiones al día y el fin de semana flojo.
        Profile(
            name: "Skin care", color: "#B0556B", icon: "sparkles",
            frequency: .daily, repetitionsPerDay: 2, isActive: true, endsDaysAgo: 0, seed: 5,
            chance: { _, _, weekday in weekday == 1 || weekday == 7 ? 0.5 : 0.8 }
        ),
        // Semanales: objetivo de 3 y de 1 veces por semana.
        Profile(
            name: "Correr", color: "#6E9440", icon: "figure.run",
            frequency: .weeklyCount(timesPerWeek: 3), repetitionsPerDay: 1,
            isActive: true, endsDaysAgo: 0, seed: 6,
            chance: { _, _, _ in 0.75 }
        ),
        Profile(
            name: "Llamar a casa", color: "#2E8F83", icon: "phone.fill",
            frequency: .weeklyCount(timesPerWeek: 1), repetitionsPerDay: 1,
            isActive: true, endsDaysAgo: 0, seed: 7,
            chance: { _, _, _ in 0.85 }
        ),
        // En pausa: su historial acaba hace ~4 meses.
        Profile(
            name: "Estirar", color: "#D4762A", icon: "figure.flexibility",
            frequency: .daily, repetitionsPerDay: 1, isActive: false, endsDaysAgo: 120, seed: 8,
            chance: { _, _, _ in 0.6 }
        ),
    ]

    /// - Returns: `true` si ha sembrado, `false` si no hacía falta.
    /// - Parameter userDefaultsSuiteName: para tests. `UserDefaults` no puede cruzar al actor, así
    ///   que entra el nombre de la suite y se construye aquí dentro. `nil` usa `.standard`.
    @discardableResult
    public func seedIfNeeded(
        userDefaultsSuiteName: String? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws -> Bool {
        let userDefaults = userDefaultsSuiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
        guard !userDefaults.bool(forKey: Self.seededKey) else { return false }
        guard try modelContext.fetchCount(FetchDescriptor<HabitEntity>()) == 0 else { return false }

        let clock = ContinuousClock()
        let start = clock.now

        let completions = try seed(now: now, calendar: calendar)
        userDefaults.set(true, forKey: Self.seededKey)

        let elapsed = start.duration(to: clock.now)
        print("[DebugHistorySeeder] Seeded \(Self.profiles.count) habits and \(completions) completions in \(elapsed).")
        return true
    }

    /// - Returns: número de completions insertadas.
    private func seed(now: Date, calendar: Calendar) throws -> Int {
        let today = calendar.startOfDay(for: now)
        guard
            let currentMonth = calendar.dateInterval(of: .month, for: today),
            let firstDay = calendar.date(byAdding: .month, value: -Self.monthsBack, to: currentMonth.start)
        else { return 0 }

        let totalDays = max(calendar.dateComponents([.day], from: firstDay, to: today).day ?? 1, 1)
        var inserted = 0

        for profile in Self.profiles {
            let habit = HabitEntity(
                id: UUID(),
                name: profile.name,
                color: profile.color,
                icon: profile.icon,
                active: profile.isActive,
                createdAt: firstDay,
                updatedAt: now
            )
            HabitMapper.apply(
                HabitSchedule(frequency: profile.frequency, repetitionsPerDay: profile.repetitionsPerDay),
                to: habit
            )
            modelContext.insert(habit)

            var generator = SplitMix64(seed: profile.seed)
            let lastDay = calendar.date(byAdding: .day, value: -profile.endsDaysAgo, to: today) ?? today

            for (day, count) in Self.completedDays(
                for: profile,
                from: firstDay,
                through: lastDay,
                totalDays: totalDays,
                calendar: calendar,
                generator: &generator
            ) {
                for repetitionIndex in 0..<count {
                    modelContext.insert(
                        HabitCompletionEntity(
                            id: UUID(),
                            habit: habit,
                            day: day,
                            repetitionIndex: repetitionIndex,
                            completedAt: calendar.date(
                                byAdding: .minute,
                                value: 8 * 60 + repetitionIndex * 180 + Int.random(in: 0..<45, using: &generator),
                                to: day
                            ) ?? day
                        )
                    )
                    inserted += 1
                }
            }
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
        return inserted
    }

    /// Día y repeticiones hechas ese día, en orden. Nunca pasa de `repetitionsPerDay`.
    private static func completedDays(
        for profile: Profile,
        from firstDay: Date,
        through lastDay: Date,
        totalDays: Int,
        calendar: Calendar,
        generator: inout SplitMix64
    ) -> [(day: Date, count: Int)] {
        var result: [(day: Date, count: Int)] = []

        /// Casi siempre completo; a veces se queda a medias.
        func repetitions(using generator: inout SplitMix64) -> Int {
            guard profile.repetitionsPerDay > 1, Double.random(in: 0..<1, using: &generator) > 0.75 else {
                return profile.repetitionsPerDay
            }
            return Int.random(in: 1..<profile.repetitionsPerDay, using: &generator)
        }

        switch profile.frequency {
        case .daily, .fixedDays:
            var day = firstDay
            while day <= lastDay {
                let weekday = calendar.component(.weekday, from: day)
                if profile.frequency.isScheduled(on: weekday) {
                    let elapsed = calendar.dateComponents([.day], from: firstDay, to: day).day ?? 0
                    let probability = profile.chance(
                        Double(elapsed) / Double(totalDays),
                        calendar.component(.month, from: day),
                        weekday
                    )
                    if Double.random(in: 0..<1, using: &generator) < probability {
                        result.append((day, repetitions(using: &generator)))
                    }
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }

        case .weeklyCount(let timesPerWeek):
            // Cada semana (de lunes a domingo) se hacen entre 0 y `timesPerWeek + 1` días, con
            // media algo por debajo del objetivo.
            var weekStart = mondayOnOrBefore(firstDay, calendar: calendar)
            while weekStart <= lastDay {
                var doneDays = 0
                for _ in 0..<(timesPerWeek + 1) where Double.random(in: 0..<1, using: &generator) < profile.chance(0, 1, 1) {
                    doneDays += 1
                }
                let days = (0..<7).shuffled(using: &generator).prefix(min(doneDays, 7)).sorted()
                for offset in days {
                    guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart),
                          day >= firstDay, day <= lastDay
                    else { continue }
                    result.append((day, repetitions(using: &generator)))
                }
                guard let next = calendar.date(byAdding: .day, value: 7, to: weekStart) else { break }
                weekStart = next
            }
        }

        return result.sorted { $0.day < $1.day }
    }

    private static func mondayOnOrBefore(_ date: Date, calendar: Calendar) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let daysSinceMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysSinceMonday, to: date) ?? date
    }
}

/// Generador con semilla fija para que el historial sea reproducible.
private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
#endif
