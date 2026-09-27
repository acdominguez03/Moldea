//
//  AVAudioApplicationMicrophonePermissionRepository.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import AVFAudio

public struct AVAudioApplicationMicrophonePermissionRepository: MicrophonePermissionRepository {
    public init() {}

    public func requestAuthorization() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    public func authorizationStatus() -> MicrophonePermissionStatusEnum {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            .granted
        case .denied:
            .denied
        case .undetermined:
            .notDetermined
        @unknown default:
            .notDetermined
        }
    }
}
