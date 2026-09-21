import Testing
import SwiftUI
@testable import Core

struct HexColorConverterTests {
    private static let paletteHexes = [
        "#C8372D", "#D4762A", "#C9A227", "#6E9440", "#3E8E7E", "#2E7D8F", "#3A6BC6",
        "#6C5BC4", "#9B4B8C", "#B0556B", "#5B6470", "#8A6A4F", "#DAD7D0",
    ]

    // MARK: Parseo

    @Test func parsesWithAndWithoutHashAndAnyCase() {
        let expected = HexColorConverter.color(fromHex: "#3A6BC6")

        #expect(expected != nil)
        #expect(HexColorConverter.color(fromHex: "3A6BC6") == expected)
        #expect(HexColorConverter.color(fromHex: "3a6bc6") == expected)
        #expect(HexColorConverter.color(fromHex: "#3a6bc6") == expected)
    }

    @Test(arguments: ["", "#", "#12345", "#1234567", "#GGGGGG", "#+12345", "blue"])
    func rejectsInvalidHex(_ hex: String) {
        #expect(HexColorConverter.color(fromHex: hex) == nil)
    }

    // MARK: Ida y vuelta

    @Test(arguments: paletteHexes)
    func roundTripKeepsThePaletteHex(_ hex: String) throws {
        let color = try #require(HexColorConverter.color(fromHex: hex))

        #expect(HexColorConverter.hex(from: color, in: EnvironmentValues()) == hex)
    }

    @Test func outputIsUppercase() throws {
        let color = try #require(HexColorConverter.color(fromHex: "#3a6bc6"))

        #expect(HexColorConverter.hex(from: color, in: EnvironmentValues()) == "#3A6BC6")
    }

    // MARK: Conversión de Color

    @Test func convertsPureRed() {
        let red = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1)

        #expect(HexColorConverter.hex(from: red, in: EnvironmentValues()) == "#FF0000")
    }

    @Test func clampsOutOfRangeComponents() {
        let color = Color(.sRGB, red: 1.5, green: -0.2, blue: 0.5, opacity: 1)

        #expect(HexColorConverter.hex(from: color, in: EnvironmentValues()) == "#FF0080")
    }
}
