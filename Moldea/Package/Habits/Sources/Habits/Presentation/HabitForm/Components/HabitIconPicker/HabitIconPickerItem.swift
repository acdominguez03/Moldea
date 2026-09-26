//
//  HabitIconPickerItem.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI
import Core

private enum Metrics {
    static let cornerRadius: CGFloat = 14
}

struct HabitIconPickerItem: View {
    @Environment(\.self) private var environment

    let systemName: String
    let name: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundStyle(
                    isSelected
                        ? ContrastingColor.foreground(on: tint, in: environment)
                        : Color.primary
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(.fill.tertiary), in: shape)
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct HabitIconPickerMoreItem: View {
    @Environment(\.self) private var environment

    let customIcon: String?
    let tint: Color
    let action: () -> Void

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
    }

    private var accessibilityName: String {
        guard let customIcon else { return String(localized: HabitsTextsEnum.iconMore) }
        return customIcon.replacingOccurrences(of: ".", with: " ")
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: customIcon ?? "plus")
                .font(.title2)
                .foregroundStyle(
                    customIcon == nil
                        ? Color.primary
                        : ContrastingColor.foreground(on: tint, in: environment)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(customIcon == nil ? Color.clear : tint, in: shape)
                .overlay {
                    if customIcon == nil {
                        shape.strokeBorder(
                            Color.primary.opacity(0.4),
                            style: StrokeStyle(lineWidth: 1, dash: [4])
                        )
                    }
                }
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityName)
        .accessibilityHint(customIcon == nil ? "" : String(localized: HabitsTextsEnum.iconMore))
        .accessibilityAddTraits(customIcon == nil ? [] : .isSelected)
    }
}

#Preview("Item") {
    HStack {
        HabitIconPickerItem(systemName: "drop", name: "Water", isSelected: true, tint: .blue, action: {})
        HabitIconPickerItem(systemName: "book", name: "Book", isSelected: false, tint: .blue, action: {})
        HabitIconPickerItem(
            systemName: "drop", name: "Water", isSelected: true,
            tint: HexColorConverter.color(fromHex: "#DAD7D0") ?? .gray, action: {}
        )
        HabitIconPickerMoreItem(customIcon: nil, tint: .blue, action: {})
        HabitIconPickerMoreItem(customIcon: "figure.run", tint: .blue, action: {})
    }
    .padding()
}
