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
}
