//
//  FoundationModelsDeviceEligibility.swift
//  Core
//
//  Created by Andrés on 24/09/2026.
//

import FoundationModels

public enum FoundationModelsDeviceEligibility {
    public static var isDeviceEligible: Bool {
        SystemLanguageModel.default.availability != .unavailable(.deviceNotEligible)
    }
}
