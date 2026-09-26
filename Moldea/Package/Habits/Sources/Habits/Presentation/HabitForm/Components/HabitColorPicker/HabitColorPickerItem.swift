//
//  SwiftUIView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI

struct HabitColorPickerItem: View {
    let color: Color
    let name: LocalizedStringResource
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .overlay(Circle().strokeBorder(.secondary, lineWidth: 1))
                .padding(4)
                .overlay {
                    if isSelected {
                        Circle().strokeBorder(Color.primary, lineWidth: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Unselected") {
    HabitColorPickerItem(
        color: HabitPaletteColor.red.color,
        name: "Red",
        isSelected: false,
        action: {}
    )
}

#Preview("Selected") {
    HabitColorPickerItem(color: HabitPaletteColor.red.color, name: "Red", isSelected: true, action: {})
}
