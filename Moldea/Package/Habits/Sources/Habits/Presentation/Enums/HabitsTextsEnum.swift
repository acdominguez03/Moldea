//
//  HabitsTextsEnum.swift
//  Habits
//
//  Created by Andrés on 18/09/2026.
//

import Foundation

public enum HabitsTexts {
    private static func resource(_ key: String) -> LocalizedStringResource {
        LocalizedStringResource(
            String.LocalizationValue(key),
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    // MARK: Screen Texts
    public static let screenTitle = resource("habits_screen_title")
    public static let emptyState = resource("habits_empty_state")
}
