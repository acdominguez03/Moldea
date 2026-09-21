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

    init() {
        do {
            let container = try MoldeaSchema.makeModelContainer()
            modelContainer = container
            habitRepository = SwiftDataHabitRepository(modelContainer: container)
        } catch {
            fatalError("No se pudo crear el ModelContainer: \(error)")
        }
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
                        SpeechToTextView()
                            .presentationDetents([.medium, .large])
                    }
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
            HabitsView(habitRepository: habitRepository)
        case .settings:
            SettingsView()
        case .microphone:
            EmptyView()
        }
    }
}
