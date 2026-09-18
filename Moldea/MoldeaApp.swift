//
//  MoldeaApp.swift
//  Moldea
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import SwiftData
import Navigation
import Today
import Statistics
import Habits
import Settings

@main
struct MoldeaApp: App {
    @State private var tabRouter = TabRouter()
    @State private var router = AppRouter(initialFlow: .tabView)
    
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
                        Text("Entrada de voz")
                    }
                }
            }
        }
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
