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
    public static let speechToTextPlaceholder = resource("speech_to_text_placeholder")
    public static let speechToTextPreparing = resource("speech_to_text_preparing")

    //MARK: Transcription Error Texts
    public static let transcriptionErrorMicrophoneNotAuthorized = resource("transcription_error_microphone_not_authorized")
    public static let transcriptionErrorUnavailable = resource("transcription_error_unavailable")
    public static let transcriptionErrorLocaleNotSupported = resource("transcription_error_locale_not_supported")
    public static let transcriptionErrorMicrophoneUnavailable = resource("transcription_error_microphone_unavailable")
    public static let transcriptionErrorInvalidAudioFormat = resource("transcription_error_invalid_audio_format")
    public static let transcriptionErrorNoCompatibleFormat = resource("transcription_error_no_compatible_format")
    public static let transcriptionErrorConversionFailed = resource("transcription_error_conversion_failed")

    public static func transcriptionErrorStageFailed(_ stage: String) -> LocalizedStringResource {
        LocalizedStringResource(
            "transcription_error_stage_failed \(stage)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    //MARK: Habits Recognizer Texts
    public static let aiCheckResponseButton = resource("ai_check_response_button")
    public static let aiNoHabitsRecognized = resource("ai_no_habits_recognized")

    public static let summaryEveryDay = resource("habits_summary_every_day")

    public static func summaryWeekdays(_ weekdays: String) -> LocalizedStringResource {
        LocalizedStringResource(
            "habits_summary_weekdays \(weekdays)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static func summaryTimesPerDay(_ count: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "habits_summary_times_per_day \(count)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static func summaryTimesPerWeek(_ count: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "habits_summary_times_per_week \(count)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static let aiCommandTitle = resource("ai_command_title")
    public static let aiCommandParsing = resource("ai_command_parsing")
    public static let aiRecognizingHabits = resource("ai_recognizing_habits")
    public static let aiCommandFrequencyDaily = resource("ai_command_frequency_daily")
    public static let aiCommandConfirm = resource("ai_command_confirm")
    public static let aiCommandRepeat = resource("ai_command_repeat")

    public static func aiCommandCreateTitle(_ name: String) -> LocalizedStringResource {
        LocalizedStringResource(
            "ai_command_create_title \(name)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static func aiCommandDeleteTitle(_ name: String) -> LocalizedStringResource {
        LocalizedStringResource(
            "ai_command_delete_title \(name)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static func aiCommandFrequencyWeekly(_ timesPerWeek: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "ai_command_frequency_weekly \(timesPerWeek)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static func aiCommandFrequencyFixedDays(_ weekdays: String) -> LocalizedStringResource {
        LocalizedStringResource(
            "ai_command_frequency_fixed_days \(weekdays)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static func aiCommandRepetitions(_ repetitions: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "ai_command_repetitions \(repetitions)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static func aiCommandCreated(_ name: String) -> LocalizedStringResource {
        LocalizedStringResource(
            "ai_command_created \(name)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static func aiCommandDeleted(_ name: String) -> LocalizedStringResource {
        LocalizedStringResource(
            "ai_command_deleted \(name)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    //MARK: AI Error Texts
    public static let aiErrorNotUnderstood = resource("ai_error_not_understood")
    public static let aiErrorHabitNotFound = resource("ai_error_habit_not_found")
    public static let aiErrorInvalidCommand = resource("ai_error_invalid_command")
    public static let aiErrorDeviceNotEligible = resource("ai_error_device_not_eligible")
    public static let aiErrorNotEnabled = resource("ai_error_not_enabled")
    public static let aiErrorModelNotReady = resource("ai_error_model_not_ready")
    public static let aiErrorUnavailableUnknown = resource("ai_error_unavailable_unknown")
    public static let aiErrorLocaleNotSupported = resource("ai_error_locale_not_supported")
    public static let aiErrorSessionUnavailable = resource("ai_error_session_unavailable")
    public static let aiErrorAssetsUnavailable = resource("ai_error_assets_unavailable")
    public static let aiErrorModelLoadFailed = resource("ai_error_model_load_failed")
    public static let aiErrorGuardrailViolation = resource("ai_error_guardrail_violation")
    public static let aiErrorRefusal = resource("ai_error_refusal")
    public static let aiErrorContextSizeExceeded = resource("ai_error_context_size_exceeded")
    public static let aiErrorRateLimited = resource("ai_error_rate_limited")
    public static let aiErrorUnsupportedCapability = resource("ai_error_unsupported_capability")
    public static let aiErrorGenerationFailed = resource("ai_error_generation_failed")

    //MARK: Transcription Stage Texts
    public static let transcriptionStagePermission = resource("transcription_stage_permission")
    public static let transcriptionStageDeviceSupport = resource("transcription_stage_device_support")
    public static let transcriptionStageAssets = resource("transcription_stage_assets")
    public static let transcriptionStageAudioFormat = resource("transcription_stage_audio_format")
    public static let transcriptionStageAudioEngine = resource("transcription_stage_audio_engine")
    public static let transcriptionStageAnalysis = resource("transcription_stage_analysis")
    public static let cancel = resource("cancel")
    public static let save = resource("save")
    
    // MARK: Announcements
    public static let announcements = resource("announcements")

    // MARK: Habit Reminder Notification
    public static let habitReminderDailySingleBody = resource("notification_habit_daily_single_body")
    public static let habitReminderFixedDaysBody = resource("notification_habit_fixed_days_body")

    public static func habitReminderDailyMultipleBody(_ repetitionsPerDay: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "notification_habit_daily_multiple_body \(repetitionsPerDay)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    public static func habitReminderWeeklyCountBody(_ timesPerWeek: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "notification_habit_weekly_count_body \(timesPerWeek)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }
}
