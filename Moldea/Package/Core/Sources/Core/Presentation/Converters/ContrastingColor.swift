//
//  ContrastingColor.swift
//  Core
//

import SwiftUI

public enum ContrastingColor {
    public static func foreground(on background: Color, in environment: EnvironmentValues) -> Color {
        let resolved = background.resolve(in: environment)
        let luminance = relativeLuminance(
            red: resolved.linearRed, green: resolved.linearGreen, blue: resolved.linearBlue
        )
        return contrastRatio(luminance, whiteLuminance) >= contrastRatio(luminance, blackLuminance)
            ? .white
            : .black
    }

    static func contrastRatioWithWhite(of background: Color, in environment: EnvironmentValues) -> Double {
        let resolved = background.resolve(in: environment)
        return contrastRatio(
            relativeLuminance(
                red: resolved.linearRed, green: resolved.linearGreen, blue: resolved.linearBlue
            ),
            whiteLuminance
        )
    }

    private static let whiteLuminance = 1.0
    private static let blackLuminance = 0.0

    private static func relativeLuminance(red: Float, green: Float, blue: Float) -> Double {
        0.2126 * clamp(red) + 0.7152 * clamp(green) + 0.0722 * clamp(blue)
    }

    private static func contrastRatio(_ first: Double, _ second: Double) -> Double {
        let lighter = max(first, second)
        let darker = min(first, second)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func clamp(_ value: Float) -> Double {
        Double(min(max(value, 0), 1))
    }
}
