import Testing
import Core
@testable import Settings

private struct FakeMicrophonePermissionRepository: MicrophonePermissionRepository {
    let status: MicrophonePermissionStatusEnum

    func requestAuthorization() async -> Bool {
        status == .granted
    }

    func authorizationStatus() -> MicrophonePermissionStatusEnum {
        status
    }
}

struct GetMicrophonePermissionStatusUseCaseTests {
    @Test(arguments: [MicrophonePermissionStatusEnum.notDetermined, .denied, .granted])
    func executeReturnsTheRepositoryStatus(status: MicrophonePermissionStatusEnum) {
        let useCase = GetMicrophonePermissionStatusUseCase(
            microphonePermissionRepository: FakeMicrophonePermissionRepository(status: status)
        )

        #expect(useCase.execute() == status)
    }
}
