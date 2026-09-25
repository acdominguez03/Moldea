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
    private let userDefaultsRepository: any UserDefaultsRepository

    nonisolated public init(userDefaultsRepository: any UserDefaultsRepository) {
        self.userDefaultsRepository = userDefaultsRepository
    }

    @MainActor
    public func scheduleReminder(for habit: Habit) async {
        print("[HabitNotificationScheduler] scheduleReminder(for:) called — habit: \"\(habit.name)\" (id: \(habit.id))")

        guard userDefaultsRepository.getBool(.isNotificationsEnabled) else {
            print("[HabitNotificationScheduler] Skipped — notifications are disabled in app settings.")
            return
        }

        guard let reminder = habit.reminder, reminder.isEnabled else {
            print("[HabitNotificationScheduler] Skipped — reminder is nil or disabled for habit \"\(habit.name)\".")
            return
        }

        let weekdays = HabitReminderMessageBuilder.weekdays(
            frequency: habit.schedule.frequency,
            isMutedOnWeekends: reminder.isMutedOnWeekends
        )
        guard !weekdays.isEmpty else {
            print("[HabitNotificationScheduler] Skipped — no weekdays to schedule for habit \"\(habit.name)\" (isMutedOnWeekends: \(reminder.isMutedOnWeekends)).")
            return
        }

        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
        let hour = timeComponents.hour ?? -1
        let minute = timeComponents.minute ?? -1

        print("[HabitNotificationScheduler] Reminder time for \"\(habit.name)\": \(String(format: "%02d:%02d", hour, minute)) — weekdays: \(weekdays.sorted()) (1 = Sunday … 7 = Saturday)")

        for weekday in weekdays.sorted() {
            var triggerComponents = timeComponents
            triggerComponents.weekday = weekday

            let identifier = notificationIdentifier(habitID: habit.id, weekday: weekday)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)

            print("[HabitNotificationScheduler] Scheduling \"\(identifier)\" — weekday \(weekday) at \(String(format: "%02d:%02d", hour, minute)), repeats: true. Next fire date: \(trigger.nextTriggerDate().map(String.init(describing:)) ?? "unknown")")

            let content = makeContent(for: habit, weekday: weekday)//, iconPNGData: iconPNGData
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await UNUserNotificationCenter.current().add(request)
                print("[HabitNotificationScheduler] ✔ Scheduled \"\(identifier)\" successfully.")
            } catch {
                print("[HabitNotificationScheduler] ✘ Failed to schedule \"\(identifier)\": \(error)")
            }
        }

        print("[HabitNotificationScheduler] Finished scheduling \(weekdays.count) request(s) for habit \"\(habit.name)\".")
    }

    private func makeContent(for habit: Habit, weekday: Int/*, iconPNGData: Data?*/) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = HabitReminderMessageBuilder.body(
            frequency: habit.schedule.frequency,
            repetitionsPerDay: habit.schedule.repetitionsPerDay
        )
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

    
    @MainActor
    public func cancelReminders(for habitID: Habit.ID) async {
        let identifiers = (1...7).map {
            notificationIdentifier(habitID: habitID, weekday: $0)
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("[HabitNotificationScheduler] Cancelled pending reminders for habit id: \(habitID)")
    }

    private func notificationIdentifier(habitID: Habit.ID, weekday: Int) -> String {
        "habit-reminder-\(habitID.uuidString)-\(weekday)"
    }
}
