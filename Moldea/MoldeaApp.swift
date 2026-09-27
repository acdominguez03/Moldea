//
//  MoldeaApp.swift
//  Moldea
//
//  Created by Andrés on 18/09/2026.
//

import AppIntents
import SwiftUI
import SwiftData
import Core
import Navigation
import Today
import Statistics
import Habits
import Settings

@main
struct MoldeaApp: App {
    @State private var tabRouter = TabRouter()
    @State private var router = AppRouter(initialFlow: .tabView)
    @Environment(\.scenePhase) private var scenePhase
    private let modelContainer: ModelContainer
    private let dependencies: AppDependencies
    private let isDeviceEligibleForAppleIntelligence = FoundationModelsDeviceEligibility.isDeviceEligible

    init() {
        do {
            let container = try MoldeaSchema.makeModelContainer(inMemory: Self.usesInMemoryStore)
            modelContainer = container
            dependencies = .live(container: container)
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
                    MainTabsView(
                        selection: $tabRouter.selectedTab,
                        showsMicrophoneTab: isDeviceEligibleForAppleIntelligence,
                        prepareSheet: {
                            await dependencies.core.requestMicrophoneAuthorization.execute()
                        }
                    ) { tab in
                        tabContent(for: tab)
                    } sheetContent: {
                        SpeechToTextView()
                            .fittingSheetDetents()
                    }
                    .debugNotificationsOverlay()
                }
            }
            .environment(\.coreDependencies, dependencies.core)
            .environment(\.habitsDependencies, dependencies.habits)
            .environment(\.todayDependencies, dependencies.today)
            .environment(\.statisticsDependencies, dependencies.statistics)
            .environment(\.settingsDependencies, dependencies.settings)
            .task {
                await dependencies.core.requestNotificationAuthorization.execute()
            }
            /*.task {
                try? SampleDataSeeder.seed(in: modelContainer)
            }*/
            .task {
                MoldeaShortcuts.updateAppShortcutParameters()
            }
            #if DEBUG
            .task {
                // Los tests de UI usan un almacén en memoria y esperan que esté vacío.
                guard !Self.usesInMemoryStore else { return }
                try? await DebugHistorySeeder(modelContainer: modelContainer).seedIfNeeded()
            }
            #endif
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .background {
                    MoldeaShortcuts.updateAppShortcutParameters()
                }
                // Repone las notificaciones de los próximos días y recoge lo que haya hecho el
                // widget mientras la app estaba cerrada.
                if phase == .active {
                    Task { await dependencies.core.notificationScheduler.syncReminders() }
                }
            }
        }
        .modelContainer(modelContainer)
    }

    @ViewBuilder
    private func tabContent(for tab: MainTab) -> some View {
        switch tab {
        case .today:
            TodayView()
        case .statistics:
            StatisticsView()
        case .habits:
            HabitsView()
        case .settings:
            SettingsView()
        case .microphone:
            EmptyView()
        }
    }
}
