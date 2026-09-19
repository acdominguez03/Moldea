import Testing
import SwiftUI
import Core
@testable import Habits

private struct ExecuteCall: Sendable, Equatable {
    let name: String
    let color: String
    let icon: String
    let frequency: HabitFrequency
    let repetitionsPerDay: Int
}

private actor FakeCreateHabitUseCase: CreateHabitUseCase {
    private(set) var calls: [ExecuteCall] = []
    private let error: (any Error)?

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func execute(
        name: String,
        color: String,
        icon: String,
        frequency: HabitFrequency,
        repetitionsPerDay: Int
    ) async throws {
        calls.append(
            ExecuteCall(
                name: name,
                color: color,
                icon: icon,
                frequency: frequency,
                repetitionsPerDay: repetitionsPerDay
            )
        )
        if let error { throw error }
    }
}

private struct UseCaseFailure: Error {}

@MainActor
struct CreateHabitViewModelTests {
    private func makeViewModel(
        useCase: FakeCreateHabitUseCase = FakeCreateHabitUseCase()
    ) -> CreateHabitViewModel {
        CreateHabitViewModel(createHabitUseCase: useCase)
    }

    // MARK: Color

    @Test func defaultColorIsGray() {
        let viewModel = makeViewModel()

        #expect(viewModel.selectedColorHex == HabitPaletteColor.gray.hex)
        #expect(viewModel.selectedColor == HabitPaletteColor.gray.color)
    }

    @Test func selectingAPaletteColorStoresItsHex() {
        let viewModel = makeViewModel()

        viewModel.selectColor(hex: HabitPaletteColor.blue.hex)

        #expect(viewModel.selectedColorHex == "#3A6BC6")
        #expect(viewModel.selectedColor == HabitPaletteColor.blue.color)
    }

    @Test func selectingACustomColorKeepsItsHex() {
        let viewModel = makeViewModel()

        viewModel.selectColor(hex: "#123ABC")

        #expect(viewModel.selectedColorHex == "#123ABC")
        #expect(viewModel.selectedColor == HexColorConverter.color(fromHex: "#123ABC"))
    }

    @Test func anUnparsableHexFallsBackToGray() {
        let viewModel = makeViewModel()

        viewModel.selectColor(hex: "not-a-color")

        #expect(viewModel.selectedColor == HabitPaletteColor.gray.color)
    }

    // MARK: canSave

    @Test func cannotSaveWithoutAName() {
        let viewModel = makeViewModel()
        #expect(!viewModel.canSave)

        viewModel.onHabitNameChanged("   ")
        #expect(!viewModel.canSave)

        viewModel.onHabitNameChanged("Leer")
        #expect(viewModel.canSave)
    }

    @Test func cannotSaveFixedDaysWithoutAnyDay() throws {
        let viewModel = makeViewModel()
        viewModel.onHabitNameChanged("Leer")
        viewModel.onFrequencyChanged(.fixedDays)
        #expect(!viewModel.canSave)

        viewModel.onWeekdayToggled(try #require(viewModel.weekdayItems.first))
        #expect(viewModel.canSave)
    }

    // MARK: save()

    @Test func savePassesTheStateToTheUseCase() async {
        let useCase = FakeCreateHabitUseCase()
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.onHabitNameChanged("Beber agua")
        viewModel.selectColor(hex: HabitPaletteColor.blue.hex)
        viewModel.selectIcon("figure.run")
        viewModel.onIncrementTimeADayClicked()

        await viewModel.save()

        #expect(await useCase.calls == [
            ExecuteCall(
                name: "Beber agua",
                color: "#3A6BC6",
                icon: "figure.run",
                frequency: .daily,
                repetitionsPerDay: 2
            )
        ])
    }

    @Test func saveTranslatesTimesPerWeek() async {
        let useCase = FakeCreateHabitUseCase()
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.onHabitNameChanged("Correr")
        viewModel.onFrequencyChanged(.timesPerWeek)
        viewModel.onIncrementTimesAWeekClicked()
        viewModel.onIncrementTimesAWeekClicked()

        await viewModel.save()

        #expect(await useCase.calls.first?.frequency == .weeklyCount(timesPerWeek: 3))
    }

    @Test func saveTranslatesFixedDays() async throws {
        let useCase = FakeCreateHabitUseCase()
        let viewModel = makeViewModel(useCase: useCase)
        viewModel.onHabitNameChanged("Gimnasio")
        viewModel.onFrequencyChanged(.fixedDays)
        let days = Array(viewModel.weekdayItems.prefix(2))
        days.forEach { viewModel.onWeekdayToggled($0) }

        await viewModel.save()

        #expect(await useCase.calls.first?.frequency == .fixedDays(weekdays: Set(days.map(\.id))))
    }

    @Test func aSuccessfulSaveMarksDidSaveWithoutError() async {
        let viewModel = makeViewModel()
        viewModel.onHabitNameChanged("Leer")
        #expect(!viewModel.didSave)

        await viewModel.save()

        #expect(viewModel.didSave)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isLoading)
    }

    @Test func aFailedSaveShowsTheGenericErrorAndDoesNotMarkDidSave() async {
        let viewModel = makeViewModel(useCase: FakeCreateHabitUseCase(error: UseCaseFailure()))
        viewModel.onHabitNameChanged("Leer")

        await viewModel.save()

        #expect(!viewModel.didSave)
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isLoading)
    }
}
