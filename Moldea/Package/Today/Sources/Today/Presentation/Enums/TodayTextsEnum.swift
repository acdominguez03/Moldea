//
//  TodayTextsEnum.swift
//  Today
//
//  Created by Andrés on 18/09/2026.
//

import Foundation

public enum TodayTexts {
    private static func resource(_ key: String) -> LocalizedStringResource {
        LocalizedStringResource(
            String.LocalizationValue(key),
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    // MARK: Screen Texts
    public static let screenTitle = resource("today_screen_title")
    public static let emptyState = resource("today_empty_state")
}
