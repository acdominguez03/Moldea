//
//  GetIsNotificationPermissionAllowedUseCase.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

import Core

protocol GetIsNotificationPermissionAllowedUseCaseProtocol: Sendable {
    func execute() -> Bool
}

struct GetIsNotificationPermissionAllowedUseCase: GetIsNotificationPermissionAllowedUseCaseProtocol {
    private let repository: UserDefaultsRepository

    init(userDefaultsRepository: UserDefaultsRepository) {
        self.repository = userDefaultsRepository
    }

    func execute() -> Bool {
        return repository.getBool(PreferenceKeyEnum.isNotificationPermissionAllowed)
    }
}
