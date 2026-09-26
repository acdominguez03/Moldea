//
//  SwiftUIView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI
import Core

struct HabitColorPicker: View {
    private static let columnCount = 7
    private static let accessibilityColumnCount = 4

    @Environment(\.self) private var environment
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let selectedHex: String
    let onColorSelected: (String) -> Void

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? Array(repeating: GridItem(.flexible(minimum: 44), spacing: 8), count: Self.accessibilityColumnCount)
            : Array(repeating: GridItem(.flexible(minimum: 28, maximum: 48), spacing: 8), count: Self.columnCount)
    }

    private var customColor: Color? {
        guard !HabitPaletteColor.allCases.contains(where: { $0.hex == selectedHex }) else {
            return nil
        }
        return HexColorConverter.color(fromHex: selectedHex)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(HabitPaletteColor.allCases) { presetItem(for: $0) }
            nativeColorPicker
        }
        .padding(.vertical, 4)
    }

    private func presetItem(for paletteColor: HabitPaletteColor) -> some View {
        HabitColorPickerItem(
            color: paletteColor.color,
            name: paletteColor.name,
            isSelected: selectedHex == paletteColor.hex,
            action: { onColorSelected(paletteColor.hex) }
        )
    }

    private var nativeColorPicker: some View {
        ColorPicker(
            selection: Binding(
                get: { customColor ?? .white },
                set: { onColorSelected(HexColorConverter.hex(from: $0, in: environment)) }
            ),
            supportsOpacity: false
        ) {
            Text(HabitsTextsEnum.colorCustom)
        }
        .labelsHidden()
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .overlay {
            if customColor != nil {
                Circle()
                    .strokeBorder(Color.primary, lineWidth: 2)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityAddTraits(customColor != nil ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selectedHex = HabitPaletteColor.gray.hex

    Form {
        HabitColorPicker(
            selectedHex: selectedHex,
            onColorSelected: { selectedHex = $0 }
        )
    }
}
