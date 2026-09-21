//
//  LanguageModelAvailabilityEnum.swift
//  Core
//
//  Created by Andrés on 21/09/2026.
//

enum LanguageModelAvailabilityEnum: Equatable {
    case available
    case unavailable(LanguageModelUnavailableReasonEnum)
}

enum LanguageModelUnavailableReasonEnum: Equatable {
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case localeNotSupported
    case unknown
}
