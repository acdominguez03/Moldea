//
//  TodayTextsEnum.swift
//  Today
//
//  Created by Andrés on 18/09/2026.
//

import Foundation

public enum TodayTextsEnum {
    private static func resource(_ key: String) -> LocalizedStringResource {
        LocalizedStringResource(
            String.LocalizationValue(key),
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    // MARK: Screen Texts
    public static let screenTitle = resource("today_screen_title")
    public static let emptyState = resource("today_empty_state")
    public static let errorTitle = resource("today_error_title")
    public static let tabPickerLabel = resource("today_tab_picker_label")
    public static let tabDaily = resource("today_tab_daily")
    public static let tabWeekly = resource("today_tab_weekly")

    // MARK: Completion Texts
    public static let completionHint = resource("today_completion_hint")

    public static func completionLabel(_ name: String) -> LocalizedStringResource {
        LocalizedStringResource(
            "today_completion_label_named \(name)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    // MARK: Progress Texts
    public static func habitsProgress(_ completed: Int, _ total: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "today_habits_progress \(completed) \(total)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static func progressToday(_ completed: Int, _ total: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "today_progress_times_today \(completed) \(total)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static func progressThisWeek(_ completed: Int, _ total: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "today_progress_times_this_week \(completed) \(total)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }
}
