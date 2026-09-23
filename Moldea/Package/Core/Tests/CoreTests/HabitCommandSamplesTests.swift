import Testing
import Foundation
@testable import Core

struct HabitCommandSamplesTests {
    private func makeDefaults(_ name: String) throws -> UserDefaults {
        let defaults = try #require(UserDefaults(suiteName: "HabitCommandSamplesTests.\(name)"))
        defaults.removePersistentDomain(forName: "HabitCommandSamplesTests.\(name)")
        return defaults
    }

    // MARK: Catálogo

    @Test(arguments: HabitCommandKindEnum.allCases)
    func `Has at least one phrase for every command`(kind: HabitCommandKindEnum) {
        #expect(HabitCommandSamples.all.contains { $0.expected == kind })
    }

    @Test func `Has no repeated phrases`() {
        let phrases = HabitCommandSamples.all.map(\.phrase)

        #expect(Set(phrases).count == phrases.count)
    }

    @Test func `Has no blank phrases`() {
        #expect(
            HabitCommandSamples.all.allSatisfy {
                !$0.phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        )
    }

    // MARK: Rotación

    @Test func `Goes through every phrase before repeating`() throws {
        let defaults = try makeDefaults(#function)
        let count = HabitCommandSamples.all.count

        let seen = (0..<count).map { _ in HabitCommandSamples.nextPhrase(defaults: defaults) }

        #expect(Set(seen).count == count)
        #expect(seen == HabitCommandSamples.all.map(\.phrase))
    }

    @Test func `Wraps around after the last phrase`() throws {
        let defaults = try makeDefaults(#function)
        let count = HabitCommandSamples.all.count

        for _ in 0..<count {
            _ = HabitCommandSamples.nextPhrase(defaults: defaults)
        }

        #expect(HabitCommandSamples.nextPhrase(defaults: defaults) == HabitCommandSamples.all[0].phrase)
    }

    @Test func `Survives a stored index beyond the catalog`() throws {
        let defaults = try makeDefaults(#function)
        defaults.set(9_999, forKey: HabitCommandSamples.rotationKey)

        let phrase = HabitCommandSamples.nextPhrase(defaults: defaults)

        #expect(HabitCommandSamples.all.map(\.phrase).contains(phrase))
    }
}
