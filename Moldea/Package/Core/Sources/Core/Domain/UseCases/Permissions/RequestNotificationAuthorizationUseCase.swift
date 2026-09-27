//
//  RequestNotificationAuthorizationUseCase.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

public protocol RequestNotificationAuthorizationUseCase: Sendable {
    @discardableResult
    func execute() async -> Bool
}

public struct DefaultRequestNotificationAuthorizationUseCase: RequestNotificationAuthorizationUseCase {
    private let notificationPermissionRepository: any NotificationPermissionRepository
    private let userDefaultsRepository: any UserDefaultsRepository

    public init(
        notificationPermissionRepository: any NotificationPermissionRepository,
        userDefaultsRepository: any UserDefaultsRepository
    ) {
        self.notificationPermissionRepository = notificationPermissionRepository
        self.userDefaultsRepository = userDefaultsRepository
    }

    @discardableResult
    public func execute() async -> Bool {
        let isAllowed = await notificationPermissionRepository.requestAuthorization()
        userDefaultsRepository.saveBool(.isNotificationPermissionAllowed, isAllowed)
        return isAllowed
    }
}
