//
//  CoreDependencies.swift
//  Core
//
//  Created by Andrés on 25/09/2026.
//

import SwiftData
import SwiftUI

public struct CoreDependencies: Sendable {
    let modelContainer: ModelContainer

    // MARK: Repositories
    public let habitRepository: any HabitRepository
    public let todayHabitsRepository: any TodayHabitsRepository
    public let userDefaultsRepository: any UserDefaultsRepository
    public let notificationScheduler: any HabitNotificationScheduler
    public let notificationPermissionRepository: any NotificationPermissionRepository
    public let microphonePermissionRepository: any MicrophonePermissionRepository
    public let todayProgressStore: any TodayProgressStore

    // MARK: Use cases
    public var createHabit: any CreateHabitUseCase {
        DefaultCreateHabitUseCase(repository: habitRepository, notificationScheduler: notificationScheduler)
    }

    public var updateHabit: any UpdateHabitUseCase {
        DefaultUpdateHabitUseCase(repository: habitRepository, notificationScheduler: notificationScheduler)
    }

    public var deleteHabit: any DeleteHabitUseCase {
        DefaultDeleteHabitUseCase(repository: habitRepository, notificationScheduler: notificationScheduler)
    }

    public var setHabitActive: any SetHabitActiveUseCase {
        DefaultSetHabitActiveUseCase(repository: habitRepository, notificationScheduler: notificationScheduler)
    }

    public var toggleHabitCompletion: any ToggleHabitCompletionUseCase {
        DefaultToggleHabitCompletionUseCase(repository: habitRepository, notificationScheduler: notificationScheduler)
    }

    public var completeHabits: any CompleteHabitsUseCase {
        DefaultCompleteHabitsUseCase(repository: habitRepository, notificationScheduler: notificationScheduler)
    }

    public var getTodayHabits: any GetTodayHabitsUseCase {
        DefaultGetTodayHabitsUseCase(repository: todayHabitsRepository)
    }

    public var calculateHabitsProgress: any CalculateHabitsProgressUseCaseProtocol {
        CalculateHabitsProgressUseCase()
    }

    public var requestNotificationAuthorization: any RequestNotificationAuthorizationUseCase {
        DefaultRequestNotificationAuthorizationUseCase(
            notificationPermissionRepository: notificationPermissionRepository,
            userDefaultsRepository: userDefaultsRepository
        )
    }

    public var requestMicrophoneAuthorization: any RequestMicrophoneAuthorizationUseCase {
        DefaultRequestMicrophoneAuthorizationUseCase(
            microphonePermissionRepository: microphonePermissionRepository,
            userDefaultsRepository: userDefaultsRepository
        )
    }

    // MARK: Factories
    public static func live(container: ModelContainer) -> Self {
        let userDefaultsRepository = UserDefaultsRepositoryImpl()
        return CoreDependencies(
            modelContainer: container,
            habitRepository: SwiftDataHabitRepository(modelContainer: container),
            todayHabitsRepository: SwiftDataTodayHabitsRepository(modelContainer: container),
            userDefaultsRepository: userDefaultsRepository,
            notificationScheduler: UNUserNotificationCenterHabitNotificationScheduler(
                userDefaultsRepository: userDefaultsRepository,
                planSource: SwiftDataReminderPlanSource(modelContainer: container)
            ),
            notificationPermissionRepository: UNUserNotificationCenterPermissionRepository(),
            microphonePermissionRepository: AVAudioApplicationMicrophonePermissionRepository(),
            todayProgressStore: UserDefaultsTodayProgressStore()
        )
    }

    public static let preview: Self = {
        let container: ModelContainer
        do {
            container = try MoldeaSchema.makeModelContainer(inMemory: true)
        } catch {
            fatalError("Could not create the preview ModelContainer: \(error)")
        }
        return CoreDependencies(
            modelContainer: container,
            habitRepository: SwiftDataHabitRepository(modelContainer: container),
            todayHabitsRepository: SwiftDataTodayHabitsRepository(modelContainer: container),
            userDefaultsRepository: InMemoryUserDefaultsRepository([
                .isNotificationPermissionAllowed: true,
                .isNotificationsEnabled: true
            ]),
            notificationScheduler: NoOpHabitNotificationScheduler(),
            notificationPermissionRepository: GrantedNotificationPermissionRepository(),
            microphonePermissionRepository: GrantedMicrophonePermissionRepository(),
            todayProgressStore: NoOpTodayProgressStore()
        )
    }()

    @MainActor func makeSpeechToTextViewModel() -> SpeechToTextViewModel {
        let parser = FoundationModelsHabitCommandParser()
        return SpeechToTextViewModel(parser: parser) {
            makeHabitCommandViewModel(parser: parser)
        }
    }

    @MainActor func makeHabitCommandViewModel(parser: any HabitCommandParsing) -> HabitCommandViewModel {
        HabitCommandViewModel(
            parser: parser,
            createHabitUseCase: createHabit,
            deleteHabitUseCase: deleteHabit,
            completeHabitsUseCase: completeHabits,
            getTodayHabitsUseCase: getTodayHabits
        )
    }
}

extension EnvironmentValues {
    @Entry public var coreDependencies: CoreDependencies? = nil
}
