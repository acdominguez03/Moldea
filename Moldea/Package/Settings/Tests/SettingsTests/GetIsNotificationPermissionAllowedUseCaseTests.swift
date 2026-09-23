import Testing
import Core
@testable import Settings

private final class FakeUserDefaultsRepository: UserDefaultsRepository, @unchecked Sendable {
    private var values: [PreferenceKey: Bool]

    init(values: [PreferenceKey: Bool] = [:]) {
        self.values = values
    }

    func getBool(_ preferenceKey: PreferenceKey) -> Bool {
        values[preferenceKey] ?? false
    }

    func saveBool(_ preferenceKey: PreferenceKey, _ value: Bool) {
        values[preferenceKey] = value
    }
}

struct GetIsNotificationPermissionAllowedUseCaseTests {
    @Test func executeReturnsTheStoredValue() {
        let repository = FakeUserDefaultsRepository(values: [.isNotificationPermissionAllowed: true])
        let useCase = GetIsNotificationPermissionAllowedUseCase(userDefaultsRepository: repository)

        #expect(useCase.execute() == true)
    }

    @Test func executeDefaultsToFalseWhenNothingIsStored() {
        let repository = FakeUserDefaultsRepository()
        let useCase = GetIsNotificationPermissionAllowedUseCase(userDefaultsRepository: repository)

        #expect(useCase.execute() == false)
    }
}
