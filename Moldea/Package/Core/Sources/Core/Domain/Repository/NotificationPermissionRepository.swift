//
//  NotificationPermissionRepository.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

public protocol NotificationPermissionRepository: Sendable {
    func requestAuthorization() async -> Bool
}
