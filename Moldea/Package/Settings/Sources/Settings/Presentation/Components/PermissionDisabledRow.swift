//
//  PermissionDisabledRow.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

import SwiftUI
import Core

struct PermissionDisabledRow: View {
    let icon: String
    let title: LocalizedStringResource
    let description: LocalizedStringResource
    let onRowTapped: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    var body: some View {
        Button(action: onRowTapped) {
            layout {
                HabitIconBadge(color: .red, icon: icon)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(SettingsTextsEnum.opensSystemSettings))
    }
}

#Preview {
    List {
        PermissionDisabledRow(
            icon: "bell.slash.fill",
            title: SettingsTextsEnum.notificationsPermissionDisabledTitle,
            description: SettingsTextsEnum.notificationsPermissionDisabledDescription,
            onRowTapped: {}
        )
        PermissionDisabledRow(
            icon: "mic.slash.fill",
            title: SettingsTextsEnum.microphonePermissionDisabledTitle,
            description: SettingsTextsEnum.microphonePermissionDisabledDescription,
            onRowTapped: {}
        )
    }
}
