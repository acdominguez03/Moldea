//
//  SwiftUIView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI

struct HabitColorPicker: View {
    let selectedColor: Color?
    let onColorSelected: (Color) -> Void

    private let itemsPerRow = 7

    private var firstRow: [HabitPaletteColor] {
        Array(HabitPaletteColor.allCases.prefix(itemsPerRow))
    }

    private var secondRow: [HabitPaletteColor] {
        Array(HabitPaletteColor.allCases.dropFirst(itemsPerRow))
    }

    private var customColor: Color? {
        guard let selectedColor,
              !HabitPaletteColor.allCases.contains(where: { $0.color == selectedColor })
        else { return nil }
        return selectedColor
    }

    var body: some View {
        VStack (spacing: 0) {
            HStack(spacing: 0) {
                ForEach(firstRow) { presetItem(for: $0) }
            }
            HStack(spacing: 0) {
                ForEach(secondRow) { presetItem(for: $0) }
                nativeColorPicker
            }
        }
    }

    private func presetItem(for paletteColor: HabitPaletteColor) -> some View {
        HabitColorPickerItem(
            color: paletteColor.color,
            name: paletteColor.name,
            isSelected: selectedColor == paletteColor.color,
            action: { onColorSelected(paletteColor.color) }
        )
        .frame(maxWidth: .infinity)
    }

    private var nativeColorPicker: some View {
        ColorPicker(
            selection: Binding(
                get: { customColor ?? .white },
                set: { onColorSelected($0) }
            ),
            supportsOpacity: false
        ) {
            Text(HabitsTextsEnum.colorCustom)
        }
        .labelsHidden()
        .frame(width: 48, height: 48)
        .overlay {
            if customColor != nil {
                Circle()
                    .strokeBorder(Color.primary, lineWidth: 2)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityAddTraits(customColor != nil ? .isSelected : [])
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @State var selectedColor: Color? = nil

    HabitColorPicker(
        selectedColor: selectedColor,
        onColorSelected: { selectedColor = $0 }
    )
    .padding()
}
