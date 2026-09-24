import Testing
import Foundation
@testable import Core

struct GetTodayProgressUseCaseTests {
    private final class FakeStore: TodayProgressStore, @unchecked Sendable {
        private(set) var requestedDays: [Date] = []
        let value: Double

        init(value: Double) {
            self.value = value
        }

        func save(fraction: Double, on day: Date) {}

        func fraction(on day: Date) -> Double {
            requestedDays.append(day)
            return value
        }
    }

    @Test func returnsTheStoredFractionForTheRequestedDay() {
        let store = FakeStore(value: 0.6)
        let day = Date(timeIntervalSince1970: 1_700_000_000)

        let fraction = DefaultGetTodayProgressUseCase(store: store).execute(on: day)

        #expect(fraction == 0.6)
        #expect(store.requestedDays == [day])
    }
}
