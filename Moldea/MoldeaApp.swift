//
//  MoldeaApp.swift
//  Moldea
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import SwiftData
import Core
import Navigation
import Today
import Statistics
import Habits
import Settings
import Core

@main
struct MoldeaApp: App {
    @State private var tabRouter = TabRouter()
    @State private var router = AppRouter(initialFlow: .tabView)
    private let modelContainer: ModelContainer
    private let habitRepository: any HabitRepository
    private let userDefaultsRepository: any UserDefaultsRepository
    private let requestNotificationAuthorizationUseCase: any RequestNotificationAuthorizationUseCase
    private let requestMicrophoneAuthorizationUseCase: any RequestMicrophoneAuthorizationUseCase

    init() {
        do {
            let container = try MoldeaSchema.makeModelContainer(inMemory: Self.usesInMemoryStore)
            modelContainer = container
            habitRepository = SwiftDataHabitRepository(modelContainer: container)
            userDefaultsRepository = UserDefaultsRepositoryImpl()
            requestNotificationAuthorizationUseCase = DefaultRequestNotificationAuthorizationUseCase(
                notificationPermissionRepository: UNUserNotificationCenterPermissionRepository(),
                userDefaultsRepository: userDefaultsRepository
            )
            requestMicrophoneAuthorizationUseCase = DefaultRequestMicrophoneAuthorizationUseCase(
                microphonePermissionRepository: AVAudioApplicationMicrophonePermissionRepository(),
                userDefaultsRepository: userDefaultsRepository
            )
        } catch {
            fatalError("No se pudo crear el ModelContainer: \(error)")
        }
    }

    /// Los tests de UI lanzan la app con `-inMemoryStore` para no tocar los datos del simulador.
    private static var usesInMemoryStore: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-inMemoryStore")
        #else
        false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView(router: router) { flow in
                switch flow {
                case .splash:
                    //TODO: Crear la pantalla de splash
                    EmptyView()
                case .tabView:
                    MainTabsView(selection: $tabRouter.selectedTab) { tab in
                        tabContent(for: tab)
                    } sheetContent: {
                        SpeechToTextView(
                            habitRepository: habitRepository,
                            userDefaultsRepository: userDefaultsRepository
                        )
                        .fittingSheetDetents()
                    }
                }
            }
            .task {
                await requestNotificationAuthorizationUseCase.execute()
                await requestMicrophoneAuthorizationUseCase.execute()
            }
            /*.task {
                try? SampleDataSeeder.seed(in: modelContainer)
            }*/
        }
        .modelContainer(modelContainer)
    }

    @ViewBuilder
    private func tabContent(for tab: MainTab) -> some View {
        switch tab {
        case .today:
            TodayView(habitRepository: habitRepository)
        case .statistics:
            StatisticsView()
        case .habits:
            HabitsView(habitRepository: habitRepository, userDefaultsRepository: userDefaultsRepository)
        case .settings:
            SettingsView(
                habitRepository: habitRepository,
                userDefaultsRepository: userDefaultsRepository
            )
        case .microphone:
            EmptyView()
        }
    }
}
