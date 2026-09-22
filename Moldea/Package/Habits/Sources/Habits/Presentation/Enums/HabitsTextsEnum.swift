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

    private static func localized(_ value: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(value, bundle: .atURL(Bundle.module.bundleURL))
    }

    // MARK: Screen Texts
    public static let screenTitle = resource("habits_screen_title")
    public static let emptyState = resource("habits_empty_state")
    
    public static let newHabit = resource("new_habit")
    public static let editHabit = resource("edit_habit")

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
    public static let colorStone = resource("habits_color_stone")
    public static let colorCustom = resource("habits_color_custom")

    // MARK: Icon Picker Texts
    public static let iconTitle = resource("habits_icon_title")
    public static let iconMore = resource("habits_icon_more")
    public static let chooseIconTitle = resource("habits_choose_icon_title")
    public static let iconDrop = resource("habits_icon_drop")
    public static let iconBook = resource("habits_icon_book")
    public static let iconBolt = resource("habits_icon_bolt")
    public static let iconTree = resource("habits_icon_tree")
    public static let iconDumbbell = resource("habits_icon_dumbbell")
    public static let iconMusicNote = resource("habits_icon_music_note")
    public static let iconPill = resource("habits_icon_pill")
    public static let iconPhone = resource("habits_icon_phone")
    public static let iconCupAndSaucer = resource("habits_icon_cup_and_saucer")
    public static let iconSunMax = resource("habits_icon_sun_max")
    public static let iconMoon = resource("habits_icon_moon")
    public static let iconHeart = resource("habits_icon_heart")
    public static let iconCalendar = resource("habits_icon_calendar")

    // MARK: Icon Chooser Texts
    public static let iconSearchPrompt = resource("habits_icon_search_prompt")
    public static let iconFamilyFitness = resource("habits_icon_family_fitness")
    public static let iconFamilyHealth = resource("habits_icon_family_health")
    public static let iconFamilyNature = resource("habits_icon_family_nature")
    public static let iconFamilyWeather = resource("habits_icon_family_weather")
    public static let iconFamilyHome = resource("habits_icon_family_home")
    public static let iconFamilyTime = resource("habits_icon_family_time")
    public static let iconFamilyObjectsAndTools = resource("habits_icon_family_objects_and_tools")
    public static let iconFamilyHuman = resource("habits_icon_family_human")
    public static let iconFamilyCommunication = resource("habits_icon_family_communication")
    public static let iconFamilyCommerce = resource("habits_icon_family_commerce")
    public static let iconFamilyMedia = resource("habits_icon_family_media")
    public static let iconFamilyTransportation = resource("habits_icon_family_transportation")
    public static let iconFamilyMaps = resource("habits_icon_family_maps")
    public static let iconFamilyGaming = resource("habits_icon_family_gaming")
    public static let iconFamilyCameraAndPhotos = resource("habits_icon_family_camera_and_photos")
    public static let iconFamilyOther = resource("habits_icon_family_other")
    
    public static let habitNamePlaceholder = resource("habit_name_placeholder")
    
    // MARK: Habit frequency
    public static let frequency = resource("frequency")
    public static let everyDayFrequency = resource("every_day_frequency")
    public static let timesPerWeekFrequency = resource("times_per_week_frequency")
    public static let fixedDaysFrequency = resource("fixed_days_frequency")
    public static let timesADay = resource("times_a_day")
    public static let timesAWeek = resource("times_a_week")

    // MARK: Habit list
    public static let summaryEveryDay = resource("habits_summary_every_day")

    public static func summaryTimesPerDay(_ count: Int) -> LocalizedStringResource {
        localized("habits_summary_times_per_day \(count)")
    }

    public static func summaryTimesPerWeek(_ count: Int) -> LocalizedStringResource {
        localized("habits_summary_times_per_week \(count)")
    }
    
    public static let days = resource("days")
    public static let activate = resource("activate")
    public static let deactivate = resource("deactivate")
    
    public static let delete = resource("delete")
    public static let confirm = resource("confirm")
    
    // MARK: Delete habit alert
    public static let deleteHabitAlertTitle = resource("delete_habit_alert_title")
    public static func deleteHabitAlertMessage(_ habitName: String) -> LocalizedStringResource {
        localized("delete_habit_alert_message \(habitName)")
    }
    
    public static let onPause = resource("on_pause")
    
    public static let habitGuidance = resource("habit_guidance")
    
    // MARK: Announcements
    public static let youWillNotReceiveNotificationsAboutThisHabit = resource("you_will_not_receive_notifications_about_this habit")
    public static let remindMeAboutThisHabit = resource("remind_me_about_this_habit")
    
    public static let youWilNotReceiveNotificationsAboutThisHabit = resource("you_will_not_receive_notifications_about_this habit")
    public static let saturdaysAndSundaysWithoutNotifications = resource("saturdays_and_sundays_without_notifications")
    public static let muteOnWeekends = resource("mute_on_weekends")
    
    public static let hour = resource("hour")
    public static func startingFrom(_ hourAndMinute: Date) -> LocalizedStringResource {
        localized("starting_from \(hourAndMinute, format: .dateTime.hour().minute())")
    }
}
