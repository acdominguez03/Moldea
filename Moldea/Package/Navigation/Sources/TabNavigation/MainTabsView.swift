//
//  MainTabsView.swift
//  Navigation
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Core

public struct MainTabsView<Content: View, SheetContent: View>: View {
    private let tabs: [MainTab] = [.today, .statistics, .habits, .settings]

    private let tabContent: (MainTab) -> Content
    private let sheetContent: () -> SheetContent
    private let selection: Binding<MainTab>
    private let accessoryAction: () -> Void

    @State private var isSheetPresented = false

    public init(
        selection: Binding<MainTab>,
        accessoryAction: @escaping () -> Void = {},
        @ViewBuilder tabContent: @escaping (MainTab) -> Content,
        @ViewBuilder sheetContent: @escaping () -> SheetContent
    ) {
        self.selection = selection
        self.accessoryAction = accessoryAction
        self.tabContent = tabContent
        self.sheetContent = sheetContent
    }

    public var body: some View {
        TabView(selection: tabSelection) {
            ForEach(tabs, id: \.self) { tab in
                Tab(value: tab) {
                    tabContent(tab)
                } label: {
                    Label(tab.description, systemImage: tab.icon)
                        .environment(\.symbolVariants, .none)
                }
            }

            Tab(value: MainTab.microphone, role: prominentRole) {
                EmptyView()
            } label: {
                Label(MainTab.microphone.description, systemImage: MainTab.microphone.icon)
                    .environment(\.symbolVariants, .none)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(isPresented: $isSheetPresented) {
            sheetContent()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var prominentRole: TabRole {
        if #available(iOS 27.0, *) {
            return .prominent
        } else {
            return .search
        }
    }

    private var tabSelection: Binding<MainTab> {
        Binding {
            selection.wrappedValue
        } set: { newValue in
            if newValue == .microphone {
                isSheetPresented = true
            } else {
                selection.wrappedValue = newValue
            }
        }
    }
}

#Preview {
    MainTabsView(selection: .constant(.today)) { tab in
        switch tab {
        case .today:
            Text("Hoy")
        case .statistics:
            Text("Estadísticas")
        case .habits:
            Text("Hábitos")
        case .settings:
            Text("Configuración")
        case .microphone:
            EmptyView()
        }
    } sheetContent: {
        Text("Entrada de voz")
    }
}
