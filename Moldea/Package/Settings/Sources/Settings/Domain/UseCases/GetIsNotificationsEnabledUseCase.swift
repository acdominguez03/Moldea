//
//  GetIsNotificationsEnabledUseCase.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import Core

protocol GetIsNotificationsEnabledUseCaseProtocol: Sendable {
    func execute() -> Bool
}

struct GetIsNotificationsEnabledUseCase: GetIsNotificationsEnabledUseCaseProtocol {
    private let repository: UserDefaultsRepository
    
    init(userDefaultsRepository: UserDefaultsRepository) {
        self.repository = userDefaultsRepository
    }
    
    func execute() -> Bool {
        return repository.getBool(PreferenceKey.isNotificationsEnabled)
    }
}
