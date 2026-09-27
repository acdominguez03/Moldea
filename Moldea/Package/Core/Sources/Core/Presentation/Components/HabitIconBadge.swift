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
    public enum StyleEnum: Sendable {
        case tinted
        case solid
    }

    public enum SizeEnum: Sendable {
        case regular
        case large

        var font: Font {
            switch self {
            case .regular: .title2
            case .large: .largeTitle
            }
        }
    }

    static let tintOpacity = 0.2
    static let minimumGlyphContrast = 3.0

    @Environment(\.self) private var environment
    @ScaledMetric(relativeTo: .title2) private var regularDimension: CGFloat = 52
    @ScaledMetric(relativeTo: .largeTitle) private var largeDimension: CGFloat = 72

    private let color: Color
    private let icon: String
    private let style: StyleEnum
    private let size: SizeEnum

    public init(color: Color, icon: String, style: StyleEnum = .tinted, size: SizeEnum = .regular) {
        self.color = color
        self.icon = icon
        self.style = style
        self.size = size
    }

    private var dimension: CGFloat {
        switch size {
        case .regular: regularDimension
        case .large: largeDimension
        }
    }

    private var effectiveStyle: StyleEnum {
        guard style == .tinted else { return style }
        let ratio = ContrastingColor.contrastRatio(
            of: color,
            onTintOf: color,
            opacity: Self.tintOpacity,
            over: Color(.secondarySystemGroupedBackground),
            in: environment
        )
        return ratio >= Self.minimumGlyphContrast ? .tinted : .solid
    }

    public var body: some View {
        let style = effectiveStyle
        Image(systemName: icon)
            .font(size.font)
            .foregroundStyle(glyphColor(for: style))
            .frame(width: dimension, height: dimension)
            .background(backgroundColor(for: style), in: Circle())
            .accessibilityHidden(true)
    }

    private func glyphColor(for style: StyleEnum) -> Color {
        switch style {
        case .tinted: color
        case .solid: ContrastingColor.foreground(on: color, in: environment)
        }
    }

    private func backgroundColor(for style: StyleEnum) -> Color {
        switch style {
        case .tinted: color.opacity(Self.tintOpacity)
        case .solid: color
        }
    }
}

#Preview {
    let color = HexColorConverter.color(fromHex: HabitAppearanceDefaultsEnum.colorHex) ?? .gray

    HStack {
        HabitIconBadge(color: color, icon: HabitAppearanceDefaultsEnum.icon)
        HabitIconBadge(color: color, icon: HabitAppearanceDefaultsEnum.icon, style: .solid, size: .large)
    }
}
