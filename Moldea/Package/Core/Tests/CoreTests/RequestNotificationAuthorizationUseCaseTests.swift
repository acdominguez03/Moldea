import Testing
@testable import Core

private actor FakeNotificationPermissionRepository: NotificationPermissionRepository {
    private let isAllowed: Bool

    init(isAllowed: Bool) {
        self.isAllowed = isAllowed
    }

    func requestAuthorization() async -> Bool {
        isAllowed
    }
}

private final class FakeUserDefaultsRepository: UserDefaultsRepository, @unchecked Sendable {
    private(set) var savedValues: [PreferenceKey: Bool] = [:]

    func getBool(_ preferenceKey: PreferenceKey) -> Bool {
        savedValues[preferenceKey] ?? false
    }

    func saveBool(_ preferenceKey: PreferenceKey, _ value: Bool) {
        savedValues[preferenceKey] = value
    }
}

struct RequestNotificationAuthorizationUseCaseTests {
    @Test func executeSavesAndReturnsGrantedPermission() async {
        let userDefaultsRepository = FakeUserDefaultsRepository()
        let useCase = DefaultRequestNotificationAuthorizationUseCase(
            notificationPermissionRepository: FakeNotificationPermissionRepository(isAllowed: true),
            userDefaultsRepository: userDefaultsRepository
        )

        let result = await useCase.execute()

        #expect(result == true)
        #expect(userDefaultsRepository.savedValues[.isNotificationPermissionAllowed] == true)
    }

    @Test func executeSavesAndReturnsDeniedPermission() async {
        let userDefaultsRepository = FakeUserDefaultsRepository()
        let useCase = DefaultRequestNotificationAuthorizationUseCase(
            notificationPermissionRepository: FakeNotificationPermissionRepository(isAllowed: false),
            userDefaultsRepository: userDefaultsRepository
        )

        let result = await useCase.execute()

        #expect(result == false)
        #expect(userDefaultsRepository.savedValues[.isNotificationPermissionAllowed] == false)
    }
}
