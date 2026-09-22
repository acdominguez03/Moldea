//
//  HexColorConverter.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import SwiftUI

public enum HexColorConverter {
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

    public static func hex(from color: Color, in environment: EnvironmentValues) -> String {
        let resolved = color.resolve(in: environment)
        return String(
            format: "#%02X%02X%02X",
            component(resolved.red), component(resolved.green), component(resolved.blue)
        )
    }

    private static func component(_ value: Float) -> Int {
        Int((min(max(value, 0), 1) * 255).rounded())
    }
}
