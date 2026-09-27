//
//  MainTabsView.swift
//  Navigation
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Core

public struct MainTabsView<Content: View, SheetContent: View>: View {
    private let tabs: [MainTabEnum] = [.today, .statistics, .habits, .settings]

    private let tabContent: (MainTabEnum) -> Content
    private let sheetContent: () -> SheetContent
    private let selection: Binding<MainTabEnum>
    private let showsMicrophoneTab: Bool
    private let prepareSheet: () async -> Void

    @State private var isSheetPresented = false
    @State private var isPreparingSheet = false

    public init(
        selection: Binding<MainTabEnum>,
        showsMicrophoneTab: Bool,
        prepareSheet: @escaping () async -> Void = {},
        @ViewBuilder tabContent: @escaping (MainTabEnum) -> Content,
        @ViewBuilder sheetContent: @escaping () -> SheetContent
    ) {
        self.selection = selection
        self.showsMicrophoneTab = showsMicrophoneTab
        self.prepareSheet = prepareSheet
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

            if showsMicrophoneTab {
                Tab(value: MainTabEnum.microphone, role: prominentRole) {
                    EmptyView()
                } label: {
                    Label(MainTabEnum.microphone.description, systemImage: MainTabEnum.microphone.icon)
                        .environment(\.symbolVariants, .none)
                        .accessibilityHint(CoreTextsEnum.voiceInputHint)
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(isPresented: $isSheetPresented) {
            NavigationStack {
                sheetContent()
            }
            .presentationDragIndicator(.visible)
        }
    }

    private var prominentRole: TabRole {
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            return .prominent
        } else {
            return .search
        }
        #else
        return .search
        #endif
    }

    private var tabSelection: Binding<MainTabEnum> {
        Binding {
            selection.wrappedValue
        } set: { newValue in
            if newValue == .microphone {
                presentSheet()
            } else {
                selection.wrappedValue = newValue
            }
        }
    }

    private func presentSheet() {
        guard !isPreparingSheet else { return }
        isPreparingSheet = true
        Task {
            await prepareSheet()
            isPreparingSheet = false
            isSheetPresented = true
        }
    }
}

#Preview {
    MainTabsView(selection: .constant(.today), showsMicrophoneTab: true) { tab in
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
