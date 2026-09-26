//
//  HabitIconPicker.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI

struct HabitIconPicker: View {
    let selectedIcon: String
    let tint: Color
    let onIconSelected: (String) -> Void
    let onMoreTapped: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 44, maximum: 52), spacing: 10)]

    private var customIcon: String? {
        HabitPaletteIcon.allCases.contains { $0.systemName == selectedIcon } ? nil : selectedIcon
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(HabitPaletteIcon.allCases) { icon in
                HabitIconPickerItem(
                    systemName: icon.systemName,
                    name: String(localized: icon.name),
                    isSelected: selectedIcon == icon.systemName,
                    tint: tint,
                    action: { onIconSelected(icon.systemName) }
                )
            }

            HabitIconPickerMoreItem(customIcon: customIcon, tint: tint, action: onMoreTapped)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    @Previewable @State var selectedIcon = HabitPaletteIcon.drop.systemName

    Form {
        HabitIconPicker(
            selectedIcon: selectedIcon,
            tint: .blue,
            onIconSelected: { selectedIcon = $0 },
            onMoreTapped: {}
        )
    }
}
