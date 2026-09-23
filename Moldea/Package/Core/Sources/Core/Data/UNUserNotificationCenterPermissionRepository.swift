//
//  UNUserNotificationCenterPermissionRepository.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import UserNotifications

public struct UNUserNotificationCenterPermissionRepository: NotificationPermissionRepository {
    public init() {}

    public func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
}
