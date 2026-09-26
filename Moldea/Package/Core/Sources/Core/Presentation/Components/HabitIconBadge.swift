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
    public enum Style: Sendable {
        case tinted
        case solid
    }

    public enum Size: Sendable {
        case regular
        case large

        var dimension: CGFloat {
            switch self {
            case .regular: 52
            case .large: 72
            }
        }

        var font: Font {
            switch self {
            case .regular: .title2
            case .large: .largeTitle
            }
        }
    }

    @Environment(\.self) private var environment

    private let color: Color
    private let icon: String
    private let style: Style
    private let size: Size

    public init(color: Color, icon: String, style: Style = .tinted, size: Size = .regular) {
        self.color = color
        self.icon = icon
        self.style = style
        self.size = size
    }

    private var glyphColor: Color {
        switch style {
        case .tinted: color
        case .solid: ContrastingColor.foreground(on: color, in: environment)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .tinted: color.opacity(0.2)
        case .solid: color
        }
    }

    public var body: some View {
        Image(systemName: icon)
            .font(size.font)
            .foregroundStyle(glyphColor)
            .frame(width: size.dimension, height: size.dimension)
            .background(backgroundColor, in: Circle())
            .accessibilityHidden(true)
    }
}

#Preview {
    let color = HexColorConverter.color(fromHex: HabitAppearanceDefaultsEnum.colorHex) ?? .gray

    HStack {
        HabitIconBadge(color: color, icon: HabitAppearanceDefaultsEnum.icon)
        HabitIconBadge(color: color, icon: HabitAppearanceDefaultsEnum.icon, style: .solid, size: .large)
    }
}
