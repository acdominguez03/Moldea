//
//  HexColorConverter.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import SwiftUI

/// Convierte entre `Color` de SwiftUI y hex `#RRGGBB`.
public enum HexColorConverter {
    /// Acepta `#RRGGBB` (el `#` es opcional; mayúsculas o minúsculas). `nil` si no es válido.
    public static func color(fromHex hex: String) -> Color? {
        var digits = hex
        if digits.hasPrefix("#") { digits.removeFirst() }
        guard digits.count == 6,
              digits.allSatisfy(\.isHexDigit),
              let value = UInt32(digits, radix: 16)
        else { return nil }

        return Color(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }

    /// Hex `#RRGGBB` en mayúsculas, resuelto en el entorno dado.
    public static func hex(from color: Color, in environment: EnvironmentValues) -> String {
        let resolved = color.resolve(in: environment)
        return String(
            format: "#%02X%02X%02X",
            component(resolved.red), component(resolved.green), component(resolved.blue)
        )
    }

    /// `Color.Resolved` usa sRGB de rango extendido: se recorta a 0...1 antes de pasar a 0...255.
    private static func component(_ value: Float) -> Int {
        Int((min(max(value, 0), 1) * 255).rounded())
    }
}
