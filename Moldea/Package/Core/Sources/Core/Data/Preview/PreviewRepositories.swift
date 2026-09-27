//
//  PreviewRepositories.swift
//  Core
//

import Foundation
import Synchronization

final class InMemoryUserDefaultsRepository: UserDefaultsRepository {
    private let values: Mutex<[String: Bool]>

    init(_ initialValues: [PreferenceKeyEnum: Bool] = [:]) {
        values = Mutex(Dictionary(uniqueKeysWithValues: initialValues.map { ($0.key.rawValue, $0.value) }))
    }

    func getBool(_ preferenceKey: PreferenceKeyEnum) -> Bool {
        let key = preferenceKey.rawValue
        return values.withLock { $0[key] ?? false }
    }

    func saveBool(_ preferenceKey: PreferenceKeyEnum, _ value: Bool) {
        let key = preferenceKey.rawValue
        values.withLock { $0[key] = value }
    }
}

struct NoOpTodayProgressStore: TodayProgressStore {
    func save(fraction: Double, on day: Date) {}
    func fraction(on day: Date) -> Double { 0 }
}

struct GrantedNotificationPermissionRepository: NotificationPermissionRepository {
    func requestAuthorization() async -> Bool { true }
}

struct GrantedMicrophonePermissionRepository: MicrophonePermissionRepository {
    func requestAuthorization() async -> Bool { true }
    func authorizationStatus() -> MicrophonePermissionStatusEnum { .granted }
}
