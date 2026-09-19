//
//  HabitsTextsEnum.swift
//  Habits
//
//  Created by Andrés on 18/09/2026.
//

import Foundation

public enum HabitsTextsEnum {
    private static func resource(_ key: String) -> LocalizedStringResource {
        LocalizedStringResource(
            String.LocalizationValue(key),
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    // MARK: Screen Texts
    public static let screenTitle = resource("habits_screen_title")
    public static let emptyState = resource("habits_empty_state")
    
    public static let newHabit = resource("new_habit")

    // MARK: Color Picker Texts
    public static let colorTitle = resource("habits_color_title")
    public static let colorRed = resource("habits_color_red")
    public static let colorOrange = resource("habits_color_orange")
    public static let colorYellow = resource("habits_color_yellow")
    public static let colorGreen = resource("habits_color_green")
    public static let colorMint = resource("habits_color_mint")
    public static let colorTeal = resource("habits_color_teal")
    public static let colorBlue = resource("habits_color_blue")
    public static let colorIndigo = resource("habits_color_indigo")
    public static let colorPurple = resource("habits_color_purple")
    public static let colorPink = resource("habits_color_pink")
    public static let colorBrown = resource("habits_color_brown")
    public static let colorGray = resource("habits_color_gray")
    public static let colorBlack = resource("habits_color_black")
    public static let colorCustom = resource("habits_color_custom")
}
