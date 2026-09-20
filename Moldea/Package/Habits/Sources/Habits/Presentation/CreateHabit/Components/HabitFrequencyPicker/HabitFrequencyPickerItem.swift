//
//  SwiftUIView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 20/9/26.
//

import SwiftUI

struct HabitFrequencyPickerItem: View {
    let frequency: HabitFrequencyEnum
    let isSelected: Bool
    let action: () -> Void
    
    private let shape = RoundedRectangle(cornerRadius: 12)
    
    var body: some View {
        Button(action: action) {
            Text(frequency.name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
        .background(isSelected ? Color.primary.opacity(0.1) : .clear, in: shape)
        .overlay {
            shape
                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
        }
        .contentShape(shape)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Unselected") {
    HStack {
        HabitFrequencyPickerItem(
            frequency: HabitFrequencyEnum.everyDay,
            isSelected: false,
            action: {}
        )
        
        HabitFrequencyPickerItem(
            frequency: HabitFrequencyEnum.everyDay,
            isSelected: true,
            action: {}
        )
    }
    .padding(.horizontal, 16)
}
