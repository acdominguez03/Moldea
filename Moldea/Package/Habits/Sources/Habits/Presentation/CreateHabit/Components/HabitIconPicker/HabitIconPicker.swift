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

    private let itemsPerRow = 7

    private var firstRow: [HabitPaletteIcon] {
        Array(HabitPaletteIcon.allCases.prefix(itemsPerRow))
    }

    private var secondRow: [HabitPaletteIcon] {
        Array(HabitPaletteIcon.allCases.dropFirst(itemsPerRow))
    }

    private var customIcon: String? {
        HabitPaletteIcon.allCases.contains { $0.systemName == selectedIcon } ? nil : selectedIcon
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(firstRow) { presetItem(for: $0) }
            }
            HStack(spacing: 0) {
                ForEach(secondRow) { presetItem(for: $0) }
                HabitIconPickerMoreItem(customIcon: customIcon, tint: tint, action: onMoreTapped)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func presetItem(for icon: HabitPaletteIcon) -> some View {
        HabitIconPickerItem(
            systemName: icon.systemName,
            name: String(localized: icon.name),
            isSelected: selectedIcon == icon.systemName,
            tint: tint,
            action: { onIconSelected(icon.systemName) }
        )
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @State var selectedIcon = HabitPaletteIcon.drop.systemName

    HabitIconPicker(
        selectedIcon: selectedIcon,
        tint: .blue,
        onIconSelected: { selectedIcon = $0 },
        onMoreTapped: {}
    )
    .padding()
}
