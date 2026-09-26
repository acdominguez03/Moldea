//
//  PendingNotificationsDebugView.swift
//  Moldea
//
//  Solo existe en DEBUG: lista las notificaciones locales pendientes con su próxima fecha.
//

import SwiftUI

#if DEBUG
import UserNotifications

extension View {
    func debugNotificationsOverlay() -> some View {
        modifier(DebugNotificationsOverlay())
    }
}

private struct DebugNotificationsOverlay: ViewModifier {
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                Button {
                    isPresented = true
                } label: {
                    Image(systemName: "ladybug")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .padding(.trailing, 16)
                .padding(.bottom, 96)
                .accessibilityLabel("Debug: notificaciones pendientes")
            }
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    PendingNotificationsDebugView()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
    }
}

struct PendingNotificationsDebugView: View {
    /// Límite medido en dispositivo con una sonda: el sistema conserva las últimas 64 añadidas.
    private static let pendingLimit = 64

    private struct Item: Identifiable {
        let id: String
        let title: String
        let nextDate: Date?
        let repeats: Bool
    }

    @State private var items: [Item] = []
    @State private var hasLoaded = false

    var body: some View {
        List {
            Section {
                Text("\(items.count) de \(Self.pendingLimit) pendientes")
                    .monospacedDigit()
            } footer: {
                Text("Ordenadas por próximo disparo. El sistema descarta en silencio las más antiguas al pasar de \(Self.pendingLimit).")
            }

            Section {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.headline)

                        if let nextDate = item.nextDate {
                            Text(nextDate, format: .dateTime.weekday(.wide).day().month(.abbreviated).hour().minute())
                        } else {
                            Text("Sin fecha de disparo")
                                .foregroundStyle(.secondary)
                        }

                        Text("\(item.repeats ? "Se repite" : "Única") · \(item.id)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .overlay {
            if hasLoaded, items.isEmpty {
                ContentUnavailableView("Sin notificaciones pendientes", systemImage: "bell.slash")
            }
        }
        .navigationTitle("Pendientes (debug)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Recargar", systemImage: "arrow.clockwise") {
                    Task { await load() }
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        items = requests
            .map { request in
                let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger
                let intervalTrigger = request.trigger as? UNTimeIntervalNotificationTrigger
                return Item(
                    id: request.identifier,
                    title: request.content.title,
                    nextDate: calendarTrigger?.nextTriggerDate() ?? intervalTrigger?.nextTriggerDate(),
                    repeats: request.trigger?.repeats ?? false
                )
            }
            .sorted { lhs, rhs in
                switch (lhs.nextDate, rhs.nextDate) {
                case let (left?, right?): left < right
                case (_?, nil): true
                case (nil, _?): false
                case (nil, nil): lhs.id < rhs.id
                }
            }
        hasLoaded = true
    }
}
#else
extension View {
    func debugNotificationsOverlay() -> some View { self }
}
#endif
