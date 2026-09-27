//
//  GetMicrophonePermissionStatusUseCase.swift
//  Settings
//
//  Created by Andrés on 27/09/2026.
//

import Core

struct GetMicrophonePermissionStatusUseCase: Sendable {
    private let repository: any MicrophonePermissionRepository

    init(microphonePermissionRepository: any MicrophonePermissionRepository) {
        self.repository = microphonePermissionRepository
    }

    func execute() -> MicrophonePermissionStatusEnum {
        repository.authorizationStatus()
    }
}
