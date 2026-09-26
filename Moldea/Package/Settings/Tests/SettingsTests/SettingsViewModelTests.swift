import Testing
import Foundation
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

private actor FakeHabitNotificationScheduler: HabitNotificationScheduler {
    private(set) var scheduledHabits: [Habit] = []
    private(set) var cancelledHabitIDs: [Habit.ID] = []
    private(set) var cancelAllCallCount = 0

    func scheduleReminder(for habit: Habit) async {
        scheduledHabits.append(habit)
    }

    func cancelReminders(for habitID: Habit.ID) async {
        cancelledHabitIDs.append(habitID)
    }

    func cancelAllReminders() async {
        cancelAllCallCount += 1
    }

    func syncReminders() async {}
}

@MainActor
struct SettingsViewModelTests {
    private func makeViewModel(
        isNotificationPermissionAllowedAtLaunch: Bool = true,
        refreshedPermission: Bool = true,
        isNotificationsEnabledAtLaunch: Bool = false,
        notificationScheduler: FakeHabitNotificationScheduler = FakeHabitNotificationScheduler()
    ) -> (SettingsViewModel, FakeRequestNotificationAuthorizationUseCase) {
        let userDefaultsRepository = FakeUserDefaultsRepository()
        userDefaultsRepository.saveBool(.isNotificationPermissionAllowed, isNotificationPermissionAllowedAtLaunch)
        userDefaultsRepository.saveBool(.isNotificationsEnabled, isNotificationsEnabledAtLaunch)
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

    // MARK: onIsNotificationsEnabledToggled

    private func makeHabit(isActive: Bool = true, hasReminder: Bool = true) -> Habit {
        Habit(
            id: UUID(),
            name: "Leer",
            color: "#007AFF",
            icon: "book",
            isActive: isActive,
            createdAt: .now,
            updatedAt: .now,
            schedule: HabitSchedule(frequency: .daily, repetitionsPerDay: 1),
            reminder: hasReminder ? HabitReminder(time: .now, isEnabled: true, isMutedOnWeekends: false) : nil
        )
    }

    @Test func disablingClearsEveryPendingNotificationWithoutTouchingHabitsOneByOne() async {
        let scheduler = FakeHabitNotificationScheduler()
        let (viewModel, _) = makeViewModel(isNotificationsEnabledAtLaunch: true, notificationScheduler: scheduler)
        let withReminder = makeHabit()
        let inactive = makeHabit(isActive: false)
        let withoutReminder = makeHabit(hasReminder: false)

        await viewModel.onIsNotificationsEnabledToggled(habits: [withReminder, inactive, withoutReminder])

        #expect(viewModel.isNotificationsEnabled == false)
        #expect(await scheduler.cancelAllCallCount == 1)
        #expect(await scheduler.cancelledHabitIDs.isEmpty)
        #expect(await scheduler.scheduledHabits.isEmpty)
    }

    @Test func enablingStartsFromACleanSlateAndSchedulesActiveHabitsWithReminder() async {
        let scheduler = FakeHabitNotificationScheduler()
        let (viewModel, _) = makeViewModel(isNotificationsEnabledAtLaunch: false, notificationScheduler: scheduler)
        let withReminder = makeHabit()
        let inactive = makeHabit(isActive: false)
        let withoutReminder = makeHabit(hasReminder: false)

        await viewModel.onIsNotificationsEnabledToggled(habits: [withReminder, inactive, withoutReminder])

        #expect(viewModel.isNotificationsEnabled == true)
        #expect(await scheduler.cancelAllCallCount == 1)
        #expect(await scheduler.scheduledHabits.map(\.id) == [withReminder.id])
        #expect(await scheduler.cancelledHabitIDs.isEmpty)
    }
}
