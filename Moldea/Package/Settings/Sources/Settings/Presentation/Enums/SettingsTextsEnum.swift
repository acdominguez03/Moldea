//
//  SettingsTextsEnum.swift
//  Settings
//
//  Created by Andrés on 18/09/2026.
//

import Foundation

public enum SettingsTexts {
    private static func resource(_ key: String) -> LocalizedStringResource {
        LocalizedStringResource(
            String.LocalizationValue(key),
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    // MARK: Screen Texts
    public static let screenTitle = resource("settings_screen_title")
    public static let generalSection = resource("settings_general_section")
}
