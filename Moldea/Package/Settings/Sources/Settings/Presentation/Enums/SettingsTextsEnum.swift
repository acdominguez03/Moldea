//
//  SettingsTextsEnum.swift
//  Settings
//
//  Created by Andrés on 18/09/2026.
//

import Foundation

public enum SettingsTextsEnum {
    private static func resource(_ key: String) -> LocalizedStringResource {
        LocalizedStringResource(
            String.LocalizationValue(key),
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    private static func localized(_ value: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(value, bundle: .atURL(Bundle.module.bundleURL))
    }

    // MARK: Screen Texts
    public static let screenTitle = resource("settings_screen_title")
    public static let generalSection = resource("settings_general_section")

    // MARK: Habit Reminders Section
    public static let habitRemindersSection = resource("settings_habit_reminders_section")
    public static let habitReminderEnabled = resource("settings_habit_reminder_enabled")
    public static let habitReminderDisabled = resource("settings_habit_reminder_disabled")

    public static func habitReminderAtTime(_ time: Date) -> LocalizedStringResource {
        localized("settings_habit_reminder_at_time \(time, format: .dateTime.hour().minute())")
    }

    // MARK: Habit Reminder Sheet
    public static let habitReminderSheetTitle = resource("settings_habit_reminder_sheet_title")
    public static let done = resource("settings_done")
    public static let habitReminderReceiveTitle = resource("settings_habit_reminder_receive_title")
    public static let habitReminderHourLabel = resource("settings_habit_reminder_hour_label")
    public static let habitReminderMuteWeekendsTitle = resource("settings_habit_reminder_mute_weekends_title")
    public static let habitReminderMuteWeekendsSubtitle = resource("settings_habit_reminder_mute_weekends_subtitle")
    
    public static let withoutWeekends = resource("without_weekends")
    public static let notifications = resource("notifications")
    
    // MARK: Allow Announcements
    public static let allowAnnouncements = resource("allow_announcements")
    public static let chooseHabitsAnnouncements = resource("choose_habits_announcements")
    public static func habitThatAnnounce(_ totalHabits: Int, _ habitsWithAnnouncement: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "habits_announce",
            defaultValue: "\(habitsWithAnnouncement) of \(totalHabits) habits announce",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }
    
    public static let everythingMuted = resource("everything_muted")

    // MARK: Notification Permission Denied
    public static let notificationsPermissionDisabledTitle = resource("settings_notifications_permission_disabled_title")
    public static let notificationsPermissionDisabledDescription = resource("settings_notifications_permission_disabled_description")

    // MARK: Accessibility
    public static let editReminder = resource("settings_edit_reminder")
    public static let opensSystemSettings = resource("settings_opens_system_settings")
}
