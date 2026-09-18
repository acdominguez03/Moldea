//
//  CoreTextsEnum.swift
//  Core
//
//  Created by Andrés on 18/09/2026.
//

import Foundation

public enum CoreTexts {
    private static func resource(_ key: String) -> LocalizedStringResource {
        LocalizedStringResource(
            String.LocalizationValue(key),
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    // MARK: TabBar Texts
    public static let todayTitle = resource("today_title")
    public static let statisticsTitle = resource("statistics_title")
    public static let habitsTitle = resource("habits_title")
    public static let settingsTitle = resource("settings_title")

    // MARK: TabBar Accessory Texts
    public static let voiceInputButton = resource("voice_input_button")
}
