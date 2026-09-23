//
//  IsNotificationsEnabledRepository.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

public protocol UserDefaultsRepository: Sendable {
    func getBool(_ preferenceKey: PreferenceKey) -> Bool
    func saveBool(_ preferenceKey: PreferenceKey, _ value: Bool)
}
