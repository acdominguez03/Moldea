//
//  FoundationModelsErrorMapper.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

import FoundationModels

enum FoundationModelsErrorMapper {
    static func unavailableReason(
        for reason: SystemLanguageModel.Availability.UnavailableReason
    ) -> LanguageModelUnavailableReasonEnum {
        switch reason {
        case .deviceNotEligible: .deviceNotEligible
        case .appleIntelligenceNotEnabled: .appleIntelligenceNotEnabled
        case .modelNotReady: .modelNotReady
        @unknown default: .unknown
        }
    }

    static func languageModelError(for error: any Error) -> LanguageModelErrorEnum {
        if error is GenerationSchema.SchemaError {
            return .generationFailed
        }

        if #available(iOS 27.0, *) {
            if let error = error as? SystemLanguageModel.Error {
                switch error {
                case .assetsUnavailable: return .assetsUnavailable
                @unknown default: return .modelLoadFailed
                }
            }

            if let error = error as? LanguageModelError {
                switch error {
                case .guardrailViolation: return .guardrailViolation
                case .refusal: return .refusal
                case .contextSizeExceeded: return .contextSizeExceeded
                case .rateLimited: return .rateLimited
                case .unsupportedLanguageOrLocale: return .localeNotSupported
                case .unsupportedCapability: return .unsupportedCapability
                default: return .generationFailed
                }
            }
        }

        if let error = error as? LanguageModelSession.GenerationError {
            switch error {
            case .guardrailViolation: return .guardrailViolation
            case .refusal: return .refusal
            case .exceededContextWindowSize: return .contextSizeExceeded
            case .rateLimited: return .rateLimited
            case .assetsUnavailable: return .assetsUnavailable
            case .unsupportedLanguageOrLocale: return .localeNotSupported
            default: return .generationFailed
            }
        }

        return .generationFailed
    }
}
