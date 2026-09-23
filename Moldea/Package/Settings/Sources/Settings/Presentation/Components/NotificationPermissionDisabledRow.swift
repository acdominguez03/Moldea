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

    var body: some View {
        Button(action: onRowTapped) {
            HStack(spacing: 12) {
                HabitIconBadge(color: .red, icon: "bell.slash.fill")

                VStack(alignment: .leading, spacing: 2) {
                    Text(SettingsTextsEnum.notificationsPermissionDisabledTitle)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(SettingsTextsEnum.notificationsPermissionDisabledDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    List {
        NotificationPermissionDisabledRow(onRowTapped: {})
    }
}
