//
//  ContrastingColor.swift
//  Core
//

import SwiftUI

public enum ContrastingColor {
    public static func foreground(on background: Color, in environment: EnvironmentValues) -> Color {
        let luminance = relativeLuminance(of: background.resolve(in: environment))
        return contrastRatio(luminance, whiteLuminance) >= contrastRatio(luminance, blackLuminance)
            ? .white
            : .black
    }

    public static func contrastRatio(
        of foreground: Color,
        on background: Color,
        in environment: EnvironmentValues
    ) -> Double {
        contrastRatio(
            relativeLuminance(of: foreground.resolve(in: environment)),
            relativeLuminance(of: background.resolve(in: environment))
        )
    }

    public static func contrastRatio(
        of foreground: Color,
        onTintOf tint: Color,
        opacity: Double,
        over background: Color,
        in environment: EnvironmentValues
    ) -> Double {
        let composited = composite(
            tint.resolve(in: environment),
            opacity: opacity,
            over: background.resolve(in: environment)
        )
        return contrastRatio(
            relativeLuminance(of: foreground.resolve(in: environment)),
            relativeLuminance(of: composited)
        )
    }

    static func contrastRatioWithWhite(of background: Color, in environment: EnvironmentValues) -> Double {
        contrastRatio(of: .white, on: background, in: environment)
    }

    private static let whiteLuminance = 1.0
    private static let blackLuminance = 0.0

    private static func composite(
        _ top: Color.Resolved,
        opacity: Double,
        over bottom: Color.Resolved
    ) -> Color.Resolved {
        let alpha = Float(min(max(opacity, 0), 1))
        func blend(_ top: Float, _ bottom: Float) -> Float {
            top * alpha + bottom * (1 - alpha)
        }
        return Color.Resolved(
            colorSpace: .sRGB,
            red: blend(top.red, bottom.red),
            green: blend(top.green, bottom.green),
            blue: blend(top.blue, bottom.blue)
        )
    }

    private static func relativeLuminance(of resolved: Color.Resolved) -> Double {
        relativeLuminance(red: resolved.linearRed, green: resolved.linearGreen, blue: resolved.linearBlue)
    }

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
