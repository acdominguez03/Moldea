import Testing
import Core
@testable import Settings

private final class FakeUserDefaultsRepository: UserDefaultsRepository, @unchecked Sendable {
    private var values: [PreferenceKey: Bool] = [:]

    func getBool(_ preferenceKey: PreferenceKey) -> Bool {
        values[preferenceKey] ?? false
    }

    func saveBool(_ preferenceKey: PreferenceKey, _ value: Bool) {
        values[preferenceKey] = value
    }
}

private actor FakeSetHabitReminderEnabledUseCase: SetHabitReminderEnabledUseCase {
    func execute(id: Habit.ID, isEnabled: Bool) async throws {}
}

private actor FakeRequestNotificationAuthorizationUseCase: RequestNotificationAuthorizationUseCase {
    private(set) var executeCallCount = 0
    private let result: Bool

    init(result: Bool) {
        self.result = result
    }

    func execute() async -> Bool {
        executeCallCount += 1
        return result
    }
}

@MainActor
struct SettingsViewModelTests {
    private func makeViewModel(
        isNotificationPermissionAllowedAtLaunch: Bool,
        refreshedPermission: Bool
    ) -> (SettingsViewModel, FakeRequestNotificationAuthorizationUseCase) {
        let userDefaultsRepository = FakeUserDefaultsRepository()
        userDefaultsRepository.saveBool(.isNotificationPermissionAllowed, isNotificationPermissionAllowedAtLaunch)
        let requestUseCase = FakeRequestNotificationAuthorizationUseCase(result: refreshedPermission)

        let viewModel = SettingsViewModel(
            setHabitReminderEnabledUseCase: FakeSetHabitReminderEnabledUseCase(),
            getIsNotificationsEnabledUseCase: GetIsNotificationsEnabledUseCase(
                userDefaultsRepository: userDefaultsRepository
            ),
            setIsNotificationsEnabledUseCase: SetIsNotificationsEnabledUseCase(
                userDefaultsRepository: userDefaultsRepository
            ),
            getIsNotificationPermissionAllowedUseCase: GetIsNotificationPermissionAllowedUseCase(
                userDefaultsRepository: userDefaultsRepository
            ),
            requestNotificationAuthorizationUseCase: requestUseCase
        )

        return (viewModel, requestUseCase)
    }

    @Test func initReflectsTheLastStoredPermissionState() {
        let (viewModel, _) = makeViewModel(
            isNotificationPermissionAllowedAtLaunch: false,
            refreshedPermission: true
        )

        #expect(viewModel.isNotificationPermissionAllowed == false)
    }

    @Test func refreshNotificationPermissionStatusQueriesTheSystemAgain() async {
        let (viewModel, requestUseCase) = makeViewModel(
            isNotificationPermissionAllowedAtLaunch: false,
            refreshedPermission: true
        )

        await viewModel.refreshNotificationPermissionStatus()

        #expect(viewModel.isNotificationPermissionAllowed == true)
        #expect(await requestUseCase.executeCallCount == 1)
    }

    @Test func refreshNotificationPermissionStatusCanRevertToDenied() async {
        let (viewModel, _) = makeViewModel(
            isNotificationPermissionAllowedAtLaunch: true,
            refreshedPermission: false
        )

        await viewModel.refreshNotificationPermissionStatus()

        #expect(viewModel.isNotificationPermissionAllowed == false)
    }
}
