import Testing
import Foundation
@testable import Core

struct UserDefaultsTodayProgressStoreTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let day = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeStore() -> UserDefaultsTodayProgressStore {
        UserDefaultsTodayProgressStore(
            suiteName: "UserDefaultsTodayProgressStoreTests.\(UUID().uuidString)",
            calendar: calendar
        )
    }

    @Test func returnsZeroWhenNothingWasSaved() {
        #expect(makeStore().fraction(on: day) == 0)
    }

    @Test func returnsTheFractionSavedForTheSameDay() {
        let store = makeStore()

        let startOfDay = calendar.startOfDay(for: day)
        store.save(fraction: 0.75, on: startOfDay)

        #expect(store.fraction(on: startOfDay.addingTimeInterval(3_600)) == 0.75)
    }

    @Test func returnsZeroOnADifferentDay() throws {
        let store = makeStore()
        store.save(fraction: 1, on: day)

        let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: day))

        #expect(store.fraction(on: tomorrow) == 0)
    }
}
