//
//  LanguageModelErrorEnum.swift
//  Core
//
//  Created by Andrés on 21/09/2026.
//

enum LanguageModelErrorEnum: Error, Equatable {
    case sessionUnavailable
    case assetsUnavailable
    case modelLoadFailed
    case guardrailViolation
    case refusal
    case contextSizeExceeded
    case rateLimited
    case localeNotSupported
    case unsupportedCapability
    case generationFailed
}
