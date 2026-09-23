//
//  SetIsNotificationsEnabledUseCase.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Core

protocol SetIsNotificationsEnabledUseCaseProtocol: Sendable {
    func execute(isEnabled: Bool) throws
}

struct SetIsNotificationsEnabledUseCase: SetIsNotificationsEnabledUseCaseProtocol {
    private let repository: UserDefaultsRepository
    
    init(userDefaultsRepository: UserDefaultsRepository) {
        self.repository = userDefaultsRepository
    }
    
    func execute(isEnabled: Bool) throws {
        repository.saveBool(PreferenceKey.isNotificationsEnabled, isEnabled)
    }
}
