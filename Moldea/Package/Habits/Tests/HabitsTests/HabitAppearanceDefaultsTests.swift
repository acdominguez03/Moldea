import Testing
import Core
@testable import Habits

struct HabitAppearanceDefaultsTests {
    @Test func `The default color is the gray from the palette`() {
        #expect(HabitAppearanceDefaultsEnum.colorHex == HabitPaletteColor.gray.hex)
    }

    @Test func `The default icon is the one the create screen starts with`() {
        #expect(HabitAppearanceDefaultsEnum.icon == HabitPaletteIcon.drop.systemName)
    }
}
