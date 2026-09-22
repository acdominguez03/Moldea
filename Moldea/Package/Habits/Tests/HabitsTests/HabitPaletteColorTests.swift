import Testing
import Core
@testable import Habits

struct HabitPaletteColorTests {
    @Test(arguments: HabitPaletteColor.allCases)
    func hexParsesToAColor(_ paletteColor: HabitPaletteColor) {
        #expect(HexColorConverter.color(fromHex: paletteColor.hex) != nil)
    }

    @Test(arguments: HabitPaletteColor.allCases)
    func hexIsUppercaseRRGGBB(_ paletteColor: HabitPaletteColor) {
        let hex = paletteColor.hex

        #expect(hex.count == 7)
        #expect(hex.hasPrefix("#"))
        #expect(hex == hex.uppercased())
    }

    @Test func hexesAreUnique() {
        let hexes = HabitPaletteColor.allCases.map(\.hex)

        #expect(Set(hexes).count == hexes.count)
    }

    @Test func paletteHasThirteenColors() {
        #expect(HabitPaletteColor.allCases.count == 13)
    }
}
