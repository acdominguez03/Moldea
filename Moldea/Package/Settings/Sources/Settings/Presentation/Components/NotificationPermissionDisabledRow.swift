//
//  NotificationPermissionDisabledRow.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

import SwiftUI
import Core

struct NotificationPermissionDisabledRow: View {
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
                HabitIconBadge(color: .red, icon: "bell.slash.fill")

                VStack(alignment: .leading, spacing: 2) {
                    Text(SettingsTextsEnum.notificationsPermissionDisabledTitle)
                        .foregroundStyle(.primary)

                    Text(SettingsTextsEnum.notificationsPermissionDisabledDescription)
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
        NotificationPermissionDisabledRow(onRowTapped: {})
    }
}
