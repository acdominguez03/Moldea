//
//  CoreTextsEnum.swift
//  Core
//
//  Created by Andrés on 18/09/2026.
//

import Foundation

public enum CoreTextsEnum {
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

    // MARK: Error Texts
    public static let genericError = resource("generic_error")
    
    //MARK: Speech to text Texts
    public static let close = resource("close")
    public static let listening = resource("listening")
    public static let finish = resource("finish")
    public static let speechToTextDescription = resource("speech_to_text_description")
}
