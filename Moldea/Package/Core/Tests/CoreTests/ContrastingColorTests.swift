import Testing
import SwiftUI
@testable import Core

struct ContrastingColorTests {
    private let environment = EnvironmentValues()

    private func color(_ hex: String) throws -> Color {
        try #require(HexColorConverter.color(fromHex: hex))
    }

    @Test func whiteBackgroundGetsBlackForeground() throws {
        #expect(ContrastingColor.foreground(on: try color("#FFFFFF"), in: environment) == .black)
    }

    @Test func blackBackgroundGetsWhiteForeground() throws {
        #expect(ContrastingColor.foreground(on: try color("#000000"), in: environment) == .white)
    }

    @Test func stoneGetsBlackForeground() throws {
        #expect(ContrastingColor.foreground(on: try color("#DAD7D0"), in: environment) == .black)
    }

    @Test(arguments: ["#C8372D", "#3A6BC6", "#6C5BC4", "#5B6470", "#8A6A4F"])
    func darkPaletteColorsGetWhiteForeground(_ hex: String) throws {
        #expect(ContrastingColor.foreground(on: try color(hex), in: environment) == .white)
    }

    @Test func blackAndWhiteRatiosMatchWCAGReference() throws {
        let onWhite = ContrastingColor.contrastRatioWithWhite(of: try color("#FFFFFF"), in: environment)
        let onBlack = ContrastingColor.contrastRatioWithWhite(of: try color("#000000"), in: environment)

        #expect(abs(onWhite - 1) < 0.001)
        #expect(abs(onBlack - 21) < 0.001)
    }

    @Test func contrastRatioIsSymmetric() throws {
        let black = try color("#000000")
        let white = try color("#FFFFFF")

        #expect(abs(ContrastingColor.contrastRatio(of: black, on: white, in: environment) - 21) < 0.001)
        #expect(abs(ContrastingColor.contrastRatio(of: white, on: black, in: environment) - 21) < 0.001)
    }

    @Test func fullyOpaqueTintMatchesPlainRatio() throws {
        let blue = try color("#3A6BC6")
        let white = try color("#FFFFFF")

        let tinted = ContrastingColor.contrastRatio(
            of: white, onTintOf: blue, opacity: 1, over: white, in: environment
        )
        let plain = ContrastingColor.contrastRatio(of: white, on: blue, in: environment)

        #expect(abs(tinted - plain) < 0.001)
    }

    @Test(arguments: ["#DAD7D0", "#C9A227", "#D4762A"])
    func lightPaletteColorsFailTintedContrastOnWhite(_ hex: String) throws {
        let tint = try color(hex)
        let ratio = ContrastingColor.contrastRatio(
            of: tint, onTintOf: tint, opacity: 0.2, over: try color("#FFFFFF"), in: environment
        )

        #expect(ratio < 3)
    }

    @Test(arguments: ["#C8372D", "#3A6BC6", "#5B6470"])
    func darkPaletteColorsPassTintedContrastOnWhite(_ hex: String) throws {
        let tint = try color(hex)
        let ratio = ContrastingColor.contrastRatio(
            of: tint, onTintOf: tint, opacity: 0.2, over: try color("#FFFFFF"), in: environment
        )

        #expect(ratio >= 3)
    }
}
