//
//  HabitIconBadge.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import SwiftUI

/// Icono del hábito sobre un círculo de su color al 20 %. Lo comparten el resumen de la pantalla
/// de creación y las filas de la lista para que se vean igual.
public struct HabitIconBadge: View {
    private let color: Color
    private let icon: String

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
    HabitIconBadge(
        color: HexColorConverter.color(fromHex: HabitAppearanceDefaultsEnum.colorHex) ?? .gray,
        icon: HabitAppearanceDefaultsEnum.icon
    )
}
