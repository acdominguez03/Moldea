import Testing
import Core
@testable import Habits

struct HabitPaletteColorTests {
    @Test(arguments: HabitPaletteColorEnum.allCases)
    func hexParsesToAColor(_ paletteColor: HabitPaletteColorEnum) {
        #expect(HexColorConverter.color(fromHex: paletteColor.hex) != nil)
    }

    @Test(arguments: HabitPaletteColorEnum.allCases)
    func hexIsUppercaseRRGGBB(_ paletteColor: HabitPaletteColorEnum) {
        let hex = paletteColor.hex

        #expect(hex.count == 7)
        #expect(hex.hasPrefix("#"))
        #expect(hex == hex.uppercased())
    }

    @Test func hexesAreUnique() {
        let hexes = HabitPaletteColorEnum.allCases.map(\.hex)

        #expect(Set(hexes).count == hexes.count)
    }

    @Test func paletteHasThirteenColors() {
        #expect(HabitPaletteColorEnum.allCases.count == 13)
    }
}
