//
//  RequestMicrophoneAuthorizationUseCase.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

public protocol RequestMicrophoneAuthorizationUseCase: Sendable {
    @discardableResult
    func execute() async -> Bool
}

public struct DefaultRequestMicrophoneAuthorizationUseCase: RequestMicrophoneAuthorizationUseCase {
    private let microphonePermissionRepository: any MicrophonePermissionRepository
    private let userDefaultsRepository: any UserDefaultsRepository

    public init(
        microphonePermissionRepository: any MicrophonePermissionRepository,
        userDefaultsRepository: any UserDefaultsRepository
    ) {
        self.microphonePermissionRepository = microphonePermissionRepository
        self.userDefaultsRepository = userDefaultsRepository
    }

    @discardableResult
    public func execute() async -> Bool {
        let isAllowed = await microphonePermissionRepository.requestAuthorization()
        userDefaultsRepository.saveBool(.isMicrophonePermissionAllowed, isAllowed)
        return isAllowed
    }
}
