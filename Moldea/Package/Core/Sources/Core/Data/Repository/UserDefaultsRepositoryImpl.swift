//
//  UsersDefaultsRepository.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Foundation

public struct UserDefaultsRepositoryImpl: UserDefaultsRepository {
    public init() {}
    
    public func getBool(_ preferenceKey: PreferenceKeyEnum) -> Bool {
        return UserDefaults.standard.bool(
            forKey: preferenceKey.rawValue
        )
    }
    
    public func saveBool(_ preferenceKey: PreferenceKeyEnum, _ value: Bool) {
        UserDefaults.standard.set(value, forKey: preferenceKey.rawValue)
    }
}
