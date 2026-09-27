//
//  UNUserNotificationCenterHabitNotificationScheduler.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

import Foundation
import SwiftUI
import UIKit
import UserNotifications

@MainActor
public struct UNUserNotificationCenterHabitNotificationScheduler: HabitNotificationScheduler {
    /// 64 pendientes por app medido en un iPhone con iOS 26 (no está en la documentación de Apple),
    /// menos un margen. Pasarse no da error: el sistema conserva en silencio las últimas añadidas.
    static let notificationBudget = 60

    private let userDefaultsRepository: any UserDefaultsRepository
    private let planSource: any ReminderPlanSource

    /// Serializa las sincronizaciones: dos a la vez se pisarían al comparar con lo pendiente.
    private static var lastSync: Task<Void, Never>?

    nonisolated public init(
        userDefaultsRepository: any UserDefaultsRepository,
        planSource: any ReminderPlanSource
    ) {
        self.userDefaultsRepository = userDefaultsRepository
        self.planSource = planSource
    }

    /// El estado que manda es el guardado: los casos de uso escriben primero y llaman después, así
    /// que basta con sincronizar. `habit` no se usa.
    @MainActor
    public func scheduleReminder(for habit: Habit) async {
        await syncReminders()
    }

    @MainActor
    public func syncReminders() async {
        let previous = Self.lastSync
        let task = Task { @MainActor in
            await previous?.value
            await performSync()
        }
        Self.lastSync = task
        await task.value
    }

    @MainActor
    private func performSync() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(ReminderPlanner.identifierPrefix) }

        guard userDefaultsRepository.getBool(.isNotificationsEnabled) else {
            await removePending(pending.map(\.identifier), from: center)
            print("[HabitNotificationScheduler] Sync — notifications are disabled in app settings; nothing pending.")
            return
        }

        let candidates: [ReminderCandidate]
        do {
            candidates = try await planSource.fetchCandidates(on: .now)
        } catch {
            // Sin datos fiables no se toca nada: peor que un aviso de más es borrar los que hay.
            print("[HabitNotificationScheduler] ✘ Sync aborted, could not read habits: \(error)")
            return
        }

        let now = Date.now
        let calendar = Calendar.current
        let includesSummary = userDefaultsRepository.getBool(.isDailySummaryEnabled)
        let planned = ReminderPlanner.plan(
            candidates: candidates,
            now: now,
            calendar: calendar,
            budget: Self.notificationBudget,
            includesDailySummary: includesSummary
        )
        let habitsByID = Dictionary(uniqueKeysWithValues: candidates.map { ($0.habit.id, $0.habit) })
        let pendingByID = Dictionary(pending.map { ($0.identifier, $0) }, uniquingKeysWith: { first, _ in first })
        let plannedIDs = Set(planned.map(\.identifier))

        // Lo que sobra (incluidos los repetitivos del esquema anterior) y lo que cambió de hora,
        // nombre o texto se quita; lo que falta se añade.
        var idsToRemove = pending.map(\.identifier).filter { !plannedIDs.contains($0) }
        var toAdd: [PlannedReminder] = []
        for reminder in planned {
            guard let content = makeContent(for: reminder, habitsByID: habitsByID, calendar: calendar) else { continue }
            if let existing = pendingByID[reminder.identifier] {
                if isUpToDate(existing, for: reminder, expected: content) { continue }
                idsToRemove.append(reminder.identifier)
            }
            toAdd.append(reminder)
        }

        await removePending(idsToRemove, from: center)

        // Completado hoy: si el aviso ya había salido, se limpia también del Centro de Notificaciones.
        var deliveredToClear = candidates
            .filter(\.isCompletedToday)
            .map { ReminderPlanner.identifier(habitID: $0.habit.id, day: now, calendar: calendar) }
        // Lo mismo con el aviso de la noche cuando ya no queda ningún hábito de hoy por completar.
        if includesSummary && ReminderPlanner.isEverythingCompletedToday(candidates: candidates, now: now, calendar: calendar) {
            deliveredToClear.append(ReminderPlanner.summaryIdentifier(day: now, calendar: calendar))
        }
        center.removeDeliveredNotifications(withIdentifiers: deliveredToClear)

        // Las más lejanas primero: si alguna vez hubiera un exceso, el sistema descarta las más
        // antiguas y así serían las que menos importan.
        for reminder in toAdd.sorted(by: { $0.fireDate > $1.fireDate }) {
            guard let content = makeContent(for: reminder, habitsByID: habitsByID, calendar: calendar) else { continue }
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: reminder.identifier,
                content: content,
                trigger: trigger
            )
            do {
                try await center.add(request)
            } catch {
                print("[HabitNotificationScheduler] ✘ Failed to schedule \"\(reminder.identifier)\": \(error)")
            }
        }

        print("[HabitNotificationScheduler] Sync — planned \(planned.count), added \(toAdd.count), removed \(idsToRemove.count).")
    }

    private func makeContent(
        for reminder: PlannedReminder,
        habitsByID: [Habit.ID: Habit],
        calendar: Calendar
    ) -> UNMutableNotificationContent? {
        switch reminder.kind {
        case .summary:
            return makeSummaryContent()
        case .habit(let habitID):
            guard let habit = habitsByID[habitID] else { return nil }
            return makeContent(for: habit, weekday: calendar.component(.weekday, from: reminder.fireDate))
        }
    }

    /// Texto fijo: solo invita a entrar a revisar los hábitos. Que aparezca o no lo decide el
    /// planificador según lo que quede por completar.
    private func makeSummaryContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = String(localized: CoreTextsEnum.dailySummaryTitle)
        content.body = String(localized: CoreTextsEnum.dailySummaryBody)
        content.sound = .default
        return content
    }

    private func isUpToDate(
        _ request: UNNotificationRequest,
        for reminder: PlannedReminder,
        expected: UNNotificationContent
    ) -> Bool {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
              let nextDate = trigger.nextTriggerDate(),
              abs(nextDate.timeIntervalSince(reminder.fireDate)) < 1
        else { return false }

        return request.content.title == expected.title && request.content.body == expected.body
    }

    @MainActor
    private func removePending(_ identifiers: [String], from center: UNUserNotificationCenter) async {
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        await waitUntil {
            await center.pendingNotificationRequests().allSatisfy { !identifiers.contains($0.identifier) }
        }
    }

    private func makeContent(for habit: Habit, weekday: Int/*, iconPNGData: Data?*/) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "¡\(habit.name)!"
        content.body = String(localized: HabitReminderMessageBuilder.body(
            frequency: habit.schedule.frequency,
            repetitionsPerDay: habit.schedule.repetitionsPerDay
        ))
        content.sound = .default

        /*if let iconPNGData, let attachment = makeIconAttachment(habitID: habit.id, weekday: weekday, pngData: iconPNGData) {
            content.attachments = [attachment]
        }*/

        return content
    }

    /*private func renderIconPNGData(for habit: Habit) -> Data? {
        let color = HexColorConverter.color(fromHex: habit.color) ?? .gray
        let renderer = ImageRenderer(content: HabitIconBadge(color: color, icon: habit.icon))
        renderer.scale = 3

        guard let uiImage = renderer.uiImage, let pngData = uiImage.pngData() else {
            print("[HabitNotificationScheduler] ✘ Could not render icon \"\(habit.icon)\" for habit \"\(habit.name)\" — notifications will have no attachment.")
            return nil
        }

        print("[HabitNotificationScheduler] Icon PNG rendered for \"\(habit.name)\" (\(pngData.count) bytes).")
        return pngData
    }*/

    /*private func makeIconAttachment(habitID: Habit.ID, weekday: Int, pngData: Data) -> UNNotificationAttachment? {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("habit-icon-\(habitID.uuidString)-\(weekday)")
            .appendingPathExtension("png")

        do {
            try pngData.write(to: fileURL, options: .atomic)
            let attachment = try UNNotificationAttachment(
                identifier: "habit-icon-\(habitID.uuidString)-\(weekday)",
                url: fileURL
            )
            print("[HabitNotificationScheduler] Icon attachment ready for weekday \(weekday) at \(fileURL.path)")
            return attachment
        } catch {
            print("[HabitNotificationScheduler] ✘ Failed to write/attach icon for weekday \(weekday): \(error)")
            return nil
        }
    }*/

    
    /// Como `scheduleReminder`: el estado guardado manda, así que sincronizar quita lo que ya no
    /// corresponde (hábito borrado, pausado o con el aviso apagado).
    @MainActor
    public func cancelReminders(for habitID: Habit.ID) async {
        await syncReminders()
    }

    /// Quita todas las notificaciones pendientes de la app, sin depender de que la base de datos
    /// sepa qué hay programado.
    @MainActor
    public func cancelAllReminders() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        await waitUntil { await center.pendingNotificationRequests().isEmpty }
        print("[HabitNotificationScheduler] Cancelled all pending reminders.")
    }

    /// El borrado de peticiones pendientes es asíncrono ("executes asynchronously, removing the
    /// pending notification requests on a secondary thread"), así que se espera a verlo aplicado
    /// antes de volver a programar. Máximo un segundo.
    private func waitUntil(_ condition: () async -> Bool) async {
        for _ in 0..<20 {
            if await condition() { return }
            try? await Task.sleep(for: .milliseconds(50))
        }
        print("[HabitNotificationScheduler] Timed out waiting for the notification center to apply the removal.")
    }
}
