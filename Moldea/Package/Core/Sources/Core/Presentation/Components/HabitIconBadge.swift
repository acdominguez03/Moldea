//
//  HabitIconBadge.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import SwiftUI

public struct HabitIconBadge: View {
    let color: Color
    let icon: String

    public init(color: Color, icon: String) {
        self.color = color
        self.icon = icon
    }

    public var body: some View {
        Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(color)
            .frame(width: 52, height: 52)
            .background(color.opacity(0.2), in: Circle())
            .accessibilityHidden(true)
    }
}

#Preview {
    HabitIconBadge(color: .blue, icon: "drop")
}
