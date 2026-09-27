import Testing
import Foundation
import Core
@testable import Settings

private final class FakeUserDefaultsRepository: UserDefaultsRepository, @unchecked Sendable {
    private var values: [PreferenceKeyEnum: Bool] = [:]

    func getBool(_ preferenceKey: PreferenceKeyEnum) -> Bool {
        values[preferenceKey] ?? false
    }

    func saveBool(_ preferenceKey: PreferenceKeyEnum, _ value: Bool) {
        values[preferenceKey] = value
    }
}

private actor FakeSetHabitReminderEnabledUseCase: SetHabitReminderEnabledUseCase {
    private(set) var calls: [(id: Habit.ID, isEnabled: Bool)] = []

    func execute(habit: Habit, isEnabled: Bool) async throws {
        calls.append((id: habit.id, isEnabled: isEnabled))
    }
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

private final class FakeMicrophonePermissionRepository: MicrophonePermissionRepository, @unchecked Sendable {
    var status: MicrophonePermissionStatusEnum

    init(status: MicrophonePermissionStatusEnum) {
        self.status = status
    }

    func requestAuthorization() async -> Bool {
        status == .granted
    }

    func authorizationStatus() -> MicrophonePermissionStatusEnum {
        status
    }
}

private actor FakeHabitNotificationScheduler: HabitNotificationScheduler {
    private(set) var scheduledHabits: [Habit] = []
    private(set) var cancelledHabitIDs: [Habit.ID] = []
    private(set) var cancelAllCallCount = 0
    private(set) var syncCallCount = 0

    func scheduleReminder(for habit: Habit) async {
        scheduledHabits.append(habit)
    }

    func cancelReminders(for habitID: Habit.ID) async {
        cancelledHabitIDs.append(habitID)
    }

    func cancelAllReminders() async {
        cancelAllCallCount += 1
    }

    func syncReminders() async {
        syncCallCount += 1
    }
}

@MainActor
struct SettingsViewModelTests {
    private func makeViewModel(
        isNotificationPermissionAllowedAtLaunch: Bool = true,
        refreshedPermission: Bool = true,
        isNotificationsEnabledAtLaunch: Bool = false,
        isDailySummaryEnabledAtLaunch: Bool = false,
        notificationScheduler: FakeHabitNotificationScheduler = FakeHabitNotificationScheduler(),
        userDefaultsRepository: FakeUserDefaultsRepository = FakeUserDefaultsRepository(),
        microphonePermissionRepository: FakeMicrophonePermissionRepository = FakeMicrophonePermissionRepository(status: .granted),
        isVoiceInputAvailable: Bool = true
    ) -> (SettingsViewModel, FakeRequestNotificationAuthorizationUseCase) {
        userDefaultsRepository.saveBool(.isNotificationPermissionAllowed, isNotificationPermissionAllowedAtLaunch)
        userDefaultsRepository.saveBool(.isNotificationsEnabled, isNotificationsEnabledAtLaunch)
        userDefaultsRepository.saveBool(.isDailySummaryEnabled, isDailySummaryEnabledAtLaunch)
        let requestUseCase = FakeRequestNotificationAuthorizationUseCase(result: refreshedPermission)

        let viewModel = SettingsViewModel(
            setHabitReminderEnabledUseCase: FakeSetHabitReminderEnabledUseCase(),
            getIsNotificationsEnabledUseCase: GetIsNotificationsEnabledUseCase(
                userDefaultsRepository: userDefaultsRepository
            ),
            setIsNotificationsEnabledUseCase: SetIsNotificationsEnabledUseCase(
                userDefaultsRepository: userDefaultsRepository,
                notificationScheduler: notificationScheduler
            ),
            getIsNotificationPermissionAllowedUseCase: GetIsNotificationPermissionAllowedUseCase(
                userDefaultsRepository: userDefaultsRepository
            ),
            getIsDailySummaryEnabledUseCase: GetIsDailySummaryEnabledUseCase(
                userDefaultsRepository: userDefaultsRepository
            ),
            setIsDailySummaryEnabledUseCase: SetIsDailySummaryEnabledUseCase(
                userDefaultsRepository: userDefaultsRepository,
                notificationScheduler: notificationScheduler
            ),
            requestNotificationAuthorizationUseCase: requestUseCase,
            getMicrophonePermissionStatusUseCase: GetMicrophonePermissionStatusUseCase(
                microphonePermissionRepository: microphonePermissionRepository
            ),
            isVoiceInputAvailable: isVoiceInputAvailable
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

    // MARK: onIsNotificationsEnabledToggled

    @Test func disablingClearsEveryPendingNotificationAndDoesNotSchedule() async {
        let scheduler = FakeHabitNotificationScheduler()
        let (viewModel, _) = makeViewModel(isNotificationsEnabledAtLaunch: true, notificationScheduler: scheduler)

        await viewModel.onIsNotificationsEnabledToggled()

        #expect(viewModel.isNotificationsEnabled == false)
        #expect(await scheduler.cancelAllCallCount == 1)
        #expect(await scheduler.cancelledHabitIDs.isEmpty)
        #expect(await scheduler.scheduledHabits.isEmpty)
        #expect(await scheduler.syncCallCount == 0)
    }

    /// Una sola sincronización programa los avisos de los hábitos y el de la noche, aunque ningún
    /// hábito tenga aviso propio.
    @Test func enablingStartsFromACleanSlateAndSyncsOnce() async {
        let scheduler = FakeHabitNotificationScheduler()
        let (viewModel, _) = makeViewModel(isNotificationsEnabledAtLaunch: false, notificationScheduler: scheduler)

        await viewModel.onIsNotificationsEnabledToggled()

        #expect(viewModel.isNotificationsEnabled == true)
        #expect(await scheduler.cancelAllCallCount == 1)
        #expect(await scheduler.syncCallCount == 1)
        #expect(await scheduler.scheduledHabits.isEmpty)
    }

    // MARK: Aviso de la noche

    @Test func theDailySummaryStartsDisabled() {
        let (viewModel, _) = makeViewModel()

        #expect(viewModel.isDailySummaryEnabled == false)
    }

    @Test func theDailySummaryReadsTheSavedPreferenceAtLaunch() {
        let (viewModel, _) = makeViewModel(isDailySummaryEnabledAtLaunch: true)

        #expect(viewModel.isDailySummaryEnabled == true)
    }

    @Test func togglingTheDailySummarySavesThePreferenceAndSyncsTheReminders() async {
        let scheduler = FakeHabitNotificationScheduler()
        let defaults = FakeUserDefaultsRepository()
        let (viewModel, _) = makeViewModel(notificationScheduler: scheduler, userDefaultsRepository: defaults)

        await viewModel.onIsDailySummaryToggled()

        #expect(viewModel.isDailySummaryEnabled == true)
        #expect(defaults.getBool(.isDailySummaryEnabled) == true)
        #expect(await scheduler.syncCallCount == 1)
        #expect(await scheduler.cancelAllCallCount == 0)
    }

    @Test func togglingTheDailySummaryTwiceTurnsItOffAgain() async {
        let scheduler = FakeHabitNotificationScheduler()
        let defaults = FakeUserDefaultsRepository()
        let (viewModel, _) = makeViewModel(notificationScheduler: scheduler, userDefaultsRepository: defaults)

        await viewModel.onIsDailySummaryToggled()
        await viewModel.onIsDailySummaryToggled()

        #expect(viewModel.isDailySummaryEnabled == false)
        #expect(defaults.getBool(.isDailySummaryEnabled) == false)
        #expect(await scheduler.syncCallCount == 2)
    }

    @Test func theDailySummaryIsIndependentOfTheMainSwitch() async {
        let defaults = FakeUserDefaultsRepository()
        let (viewModel, _) = makeViewModel(isNotificationsEnabledAtLaunch: true, userDefaultsRepository: defaults)

        await viewModel.onIsDailySummaryToggled()

        #expect(viewModel.isNotificationsEnabled == true)
        #expect(defaults.getBool(.isNotificationsEnabled) == true)
    }

    // MARK: Permiso de micrófono

    @Test func theMicrophoneRowShowsWhenThePermissionIsDeniedOnAnEligibleDevice() {
        let (viewModel, _) = makeViewModel(
            microphonePermissionRepository: FakeMicrophonePermissionRepository(status: .denied)
        )

        #expect(viewModel.showsMicrophonePermissionRow == true)
    }

    @Test(arguments: [MicrophonePermissionStatusEnum.notDetermined, .granted])
    func theMicrophoneRowIsHiddenUnlessThePermissionIsDenied(status: MicrophonePermissionStatusEnum) {
        let (viewModel, _) = makeViewModel(
            microphonePermissionRepository: FakeMicrophonePermissionRepository(status: status)
        )

        #expect(viewModel.showsMicrophonePermissionRow == false)
    }

    @Test func theMicrophoneRowIsHiddenWhenVoiceInputIsUnavailable() {
        let (viewModel, _) = makeViewModel(
            microphonePermissionRepository: FakeMicrophonePermissionRepository(status: .denied),
            isVoiceInputAvailable: false
        )

        #expect(viewModel.showsMicrophonePermissionRow == false)
    }

    @Test func refreshMicrophonePermissionStatusReadsTheCurrentState() {
        let microphone = FakeMicrophonePermissionRepository(status: .denied)
        let (viewModel, _) = makeViewModel(microphonePermissionRepository: microphone)

        microphone.status = .granted
        viewModel.refreshMicrophonePermissionStatus()

        #expect(viewModel.showsMicrophonePermissionRow == false)
    }
}
