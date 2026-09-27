import Testing
@testable import Core

private actor FakeMicrophonePermissionRepository: MicrophonePermissionRepository {
    private let isAllowed: Bool

    init(isAllowed: Bool) {
        self.isAllowed = isAllowed
    }

    func requestAuthorization() async -> Bool {
        isAllowed
    }

    nonisolated func authorizationStatus() -> MicrophonePermissionStatusEnum {
        isAllowed ? .granted : .denied
    }
}

private final class FakeUserDefaultsRepository: UserDefaultsRepository, @unchecked Sendable {
    private(set) var savedValues: [PreferenceKeyEnum: Bool] = [:]

    func getBool(_ preferenceKey: PreferenceKeyEnum) -> Bool {
        savedValues[preferenceKey] ?? false
    }

    func saveBool(_ preferenceKey: PreferenceKeyEnum, _ value: Bool) {
        savedValues[preferenceKey] = value
    }
}

struct RequestMicrophoneAuthorizationUseCaseTests {
    @Test func executeSavesAndReturnsGrantedPermission() async {
        let userDefaultsRepository = FakeUserDefaultsRepository()
        let useCase = DefaultRequestMicrophoneAuthorizationUseCase(
            microphonePermissionRepository: FakeMicrophonePermissionRepository(isAllowed: true),
            userDefaultsRepository: userDefaultsRepository
        )

        let result = await useCase.execute()

        #expect(result == true)
        #expect(userDefaultsRepository.savedValues[.isMicrophonePermissionAllowed] == true)
    }

    @Test func executeSavesAndReturnsDeniedPermission() async {
        let userDefaultsRepository = FakeUserDefaultsRepository()
        let useCase = DefaultRequestMicrophoneAuthorizationUseCase(
            microphonePermissionRepository: FakeMicrophonePermissionRepository(isAllowed: false),
            userDefaultsRepository: userDefaultsRepository
        )

        let result = await useCase.execute()

        #expect(result == false)
        #expect(userDefaultsRepository.savedValues[.isMicrophonePermissionAllowed] == false)
    }
}
