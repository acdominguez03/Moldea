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

    /// El argumento es la etapa de la sesión que ha fallado, ya resuelta al idioma actual.
    public static func transcriptionErrorStageFailed(_ stage: String) -> LocalizedStringResource {
        LocalizedStringResource(
            "transcription_error_stage_failed \(stage)",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }

    //MARK: Transcription Stage Texts
    public static let transcriptionStagePermission = resource("transcription_stage_permission")
    public static let transcriptionStageDeviceSupport = resource("transcription_stage_device_support")
    public static let transcriptionStageAssets = resource("transcription_stage_assets")
    public static let transcriptionStageAudioFormat = resource("transcription_stage_audio_format")
    public static let transcriptionStageAudioEngine = resource("transcription_stage_audio_engine")
    public static let transcriptionStageAnalysis = resource("transcription_stage_analysis")
    public static let cancel = resource("cancel")
    public static let save = resource("save")
}
