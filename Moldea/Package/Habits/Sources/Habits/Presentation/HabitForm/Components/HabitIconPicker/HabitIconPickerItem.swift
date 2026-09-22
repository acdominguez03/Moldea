//
//  HabitIconPickerItem.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI

private enum Metrics {
    static let size: CGFloat = 48
    static let inset: CGFloat = 5
    static let cornerRadius: CGFloat = 14
}

struct HabitIconPickerItem: View {
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
                .font(.title3)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isSelected ? tint : Color.clear, in: shape)
                .overlay { shape.strokeBorder(Color.primary.opacity(0.15), lineWidth: 1) }
                .padding(Metrics.inset)
                .frame(width: Metrics.size, height: Metrics.size)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct HabitIconPickerMoreItem: View {
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
                .font(.title3)
                .foregroundStyle(customIcon == nil ? Color.primary : Color.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(customIcon == nil ? Color.clear : tint, in: shape)
                .overlay {
                    shape.strokeBorder(
                        Color.primary.opacity(0.4),
                        style: StrokeStyle(lineWidth: 1, dash: [4])
                    )
                }
                .padding(Metrics.inset)
                .frame(width: Metrics.size, height: Metrics.size)
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
        HabitIconPickerMoreItem(customIcon: nil, tint: .blue, action: {})
        HabitIconPickerMoreItem(customIcon: "figure.run", tint: .blue, action: {})
    }
}
