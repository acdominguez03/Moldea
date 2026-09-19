//
//  SwiftUIView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI
import Core

struct HabitColorPicker: View {
    @Environment(\.self) private var environment

    /// Hex `#RRGGBB` del color seleccionado.
    let selectedHex: String
    let onColorSelected: (String) -> Void

    private let itemsPerRow = 7

    private var firstRow: [HabitPaletteColor] {
        Array(HabitPaletteColor.allCases.prefix(itemsPerRow))
    }

    private var secondRow: [HabitPaletteColor] {
        Array(HabitPaletteColor.allCases.dropFirst(itemsPerRow))
    }

    /// El color elegido con el selector nativo; `nil` si es uno de la paleta.
    private var customColor: Color? {
        guard !HabitPaletteColor.allCases.contains(where: { $0.hex == selectedHex }) else {
            return nil
        }
        return HexColorConverter.color(fromHex: selectedHex)
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
            isSelected: selectedHex == paletteColor.hex,
            action: { onColorSelected(paletteColor.hex) }
        )
        .frame(maxWidth: .infinity)
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
    @Previewable @State var selectedHex = HabitPaletteColor.gray.hex

    HabitColorPicker(
        selectedHex: selectedHex,
        onColorSelected: { selectedHex = $0 }
    )
    .padding()
}
