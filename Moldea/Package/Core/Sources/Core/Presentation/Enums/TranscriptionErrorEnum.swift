//
//  TranscriptionErrorEnum.swift
//  Core
//
//  Created by Andrés on 19/09/2026.
//

import Foundation

enum TranscriptionErrorEnum: Error {
    case microphoneNotAuthorized
    case microphoneUnavailable
    case transcriptionUnavailable
    case localeNotSupported
    case invalidAudioFormat
    case noCompatibleAudioFormat
    case audioConversionFailed
    case stageFailed(StageEnum, any Error)

    /// Texto que se enseña al usuario. El error subyacente de `stageFailed` no se publica:
    /// no está traducido y solo sirve para diagnóstico, así que se queda en el log.
    var message: LocalizedStringResource {
        switch self {
        case .microphoneNotAuthorized:
            CoreTextsEnum.transcriptionErrorMicrophoneNotAuthorized
        case .microphoneUnavailable:
            CoreTextsEnum.transcriptionErrorMicrophoneUnavailable
        case .transcriptionUnavailable:
            CoreTextsEnum.transcriptionErrorUnavailable
        case .localeNotSupported:
            CoreTextsEnum.transcriptionErrorLocaleNotSupported
        case .invalidAudioFormat:
            CoreTextsEnum.transcriptionErrorInvalidAudioFormat
        case .noCompatibleAudioFormat:
            CoreTextsEnum.transcriptionErrorNoCompatibleFormat
        case .audioConversionFailed:
            CoreTextsEnum.transcriptionErrorConversionFailed
        case .stageFailed(let stage, _):
            CoreTextsEnum.transcriptionErrorStageFailed(String(localized: stage.label))
        }
    }
}
