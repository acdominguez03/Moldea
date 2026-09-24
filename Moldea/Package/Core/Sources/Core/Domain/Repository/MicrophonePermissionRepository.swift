//
//  MicrophonePermissionRepository.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

public protocol MicrophonePermissionRepository: Sendable {
    func requestAuthorization() async -> Bool
}
