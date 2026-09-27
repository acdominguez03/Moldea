import Testing
import Foundation
import SwiftUI
import Core
@testable import Habits

private struct ExecuteCall: Sendable, Equatable {
    let name: String
    let color: String
    let icon: String
    let frequency: HabitFrequency
    let repetitionsPerDay: Int
    let isReminderEnabled: Bool
    let reminderTime: Date
    let isMutedOnWeekends: Bool
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
        repetitionsPerDay: Int,
        isReminderEnabled: Bool,
        reminderTime: Date,
        isMutedOnWeekends: Bool
    ) async throws {
        calls.append(
            ExecuteCall(
                name: name,
                color: color,
                icon: icon,
                frequency: frequency,
                repetitionsPerDay: repetitionsPerDay,
                isReminderEnabled: isReminderEnabled,
                reminderTime: reminderTime,
                isMutedOnWeekends: isMutedOnWeekends
            )
        )
        if let error { throw error }
    }
}

private struct UpdateExecuteCall: Sendable, Equatable {
    let id: Habit.ID
    let isActive: Bool
    let name: String
    let color: String
    let icon: String
    let frequency: HabitFrequency
    let repetitionsPerDay: Int
    let isReminderEnabled: Bool
    let reminderTime: Date
    let isMutedOnWeekends: Bool
}

private actor FakeUpdateHabitUseCase: UpdateHabitUseCase {
    private(set) var calls: [UpdateExecuteCall] = []
    private let error: (any Error)?

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func execute(
        id: Habit.ID,
        isActive: Bool,
        name: String,
        color: String,
        icon: String,
        frequency: HabitFrequency,
        repetitionsPerDay: Int,
        isReminderEnabled: Bool,
        reminderTime: Date,
        isMutedOnWeekends: Bool
    ) async throws {
        calls.append(
            UpdateExecuteCall(
                id: id,
                isActive: isActive,
                name: name,
                color: color,
                icon: icon,
                frequency: frequency,
                repetitionsPerDay: repetitionsPerDay,
                isReminderEnabled: isReminderEnabled,
                reminderTime: reminderTime,
                isMutedOnWeekends: isMutedOnWeekends
            )
        )
        if let error { throw error }
    }
}

private struct UseCaseFailure: Error {}

private let fixedReminderTime = Date(timeIntervalSince1970: 2_000)

@MainActor
struct HabitFormViewModelTests {
    private func makeViewModel(
        id: Habit.ID? = nil,
        isActive: Bool = true,
        name: String = "",
        color: String = HabitPaletteColorEnum.gray.hex,
        icon: String = HabitPaletteIconEnum.drop.systemName,
        frequency: HabitFrequency = .daily,
        repetitionsPerDay: Int = 1,
        useCase: FakeCreateHabitUseCase = FakeCreateHabitUseCase(),
        updateUseCase: FakeUpdateHabitUseCase = FakeUpdateHabitUseCase()
    ) -> HabitFormViewModel {
        HabitFormViewModel(
            id: id,
            isActive: isActive,
            name: name,
            color: color,
            icon: icon,
            frequency: frequency,
            repetitionsPerDay: repetitionsPerDay,
            createHabitUseCase: useCase,
            updateHabitUseCase: updateUseCase,
            reminderTime: fixedReminderTime
        )
    }

    // MARK: Precarga

    @Test func initWithoutIDIsNotEditing() {
        let viewModel = makeViewModel()

        #expect(!viewModel.isEditing)
    }

    @Test func initWithIDPrefillsTheBasicFields() {
        let id = UUID()
        let viewModel = makeViewModel(
            id: id,
            name: "Meditar",
            color: HabitPaletteColorEnum.mint.hex,
            icon: "leaf",
            frequency: .daily,
            repetitionsPerDay: 3
        )

        #expect(viewModel.isEditing)
        #expect(viewModel.name == "Meditar")
        #expect(viewModel.selectedColorHex == HabitPaletteColorEnum.mint.hex)
        #expect(viewModel.selectedIcon == "leaf")
        #expect(viewModel.selectedTimesADay == 3)
        #expect(viewModel.selectedFrequency == .everyDay)
    }

    @Test func initWithWeeklyCountFrequencyPrefillsTimesAWeek() {
        let viewModel = makeViewModel(id: UUID(), frequency: .weeklyCount(timesPerWeek: 4))

        #expect(viewModel.selectedFrequency == .timesPerWeek)
        #expect(viewModel.selectedTimesAWeek == 4)
    }

    @Test func initWithFixedDaysFrequencyPrefillsTheWeekdays() {
        let viewModel = makeViewModel(id: UUID(), frequency: .fixedDays(weekdays: [2, 4, 6]))

        #expect(viewModel.selectedFrequency == .fixedDays)
        #expect(viewModel.selectedWeekdays == [2, 4, 6])
    }

    // MARK: Color

    @Test func defaultColorIsGray() {
        let viewModel = makeViewModel()

        #expect(viewModel.selectedColorHex == HabitPaletteColorEnum.gray.hex)
        #expect(viewModel.selectedColor == HabitPaletteColorEnum.gray.color)
    }

    @Test func selectingAPaletteColorStoresItsHex() {
        let viewModel = makeViewModel()

        viewModel.selectColor(hex: HabitPaletteColorEnum.blue.hex)

        #expect(viewModel.selectedColorHex == "#3A6BC6")
        #expect(viewModel.selectedColor == HabitPaletteColorEnum.blue.color)
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

        #expect(viewModel.selectedColor == HabitPaletteColorEnum.gray.color)
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
        viewModel.selectColor(hex: HabitPaletteColorEnum.blue.hex)
        viewModel.selectIcon("figure.run")
        viewModel.onIncrementTimeADayClicked()

        await viewModel.save()

        #expect(await useCase.calls == [
            ExecuteCall(
                name: "Beber agua",
                color: "#3A6BC6",
                icon: "figure.run",
                frequency: .daily,
                repetitionsPerDay: 2,
                isReminderEnabled: false,
                reminderTime: fixedReminderTime,
                isMutedOnWeekends: false
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

    @Test func saveWithoutIDCallsCreateAndNotUpdate() async {
        let createUseCase = FakeCreateHabitUseCase()
        let updateUseCase = FakeUpdateHabitUseCase()
        let viewModel = makeViewModel(useCase: createUseCase, updateUseCase: updateUseCase)
        viewModel.onHabitNameChanged("Leer")

        await viewModel.save()

        #expect(await createUseCase.calls.count == 1)
        #expect(await updateUseCase.calls.isEmpty)
    }

    @Test func saveWithIDCallsUpdateWithTheGivenIDAndNotCreate() async {
        let id = UUID()
        let createUseCase = FakeCreateHabitUseCase()
        let updateUseCase = FakeUpdateHabitUseCase()
        let viewModel = makeViewModel(
            id: id,
            name: "Meditar",
            useCase: createUseCase,
            updateUseCase: updateUseCase
        )
        viewModel.onHabitNameChanged("Meditar cada día")
        viewModel.selectColor(hex: HabitPaletteColorEnum.blue.hex)
        viewModel.selectIcon("leaf")

        await viewModel.save()

        #expect(await createUseCase.calls.isEmpty)
        #expect(await updateUseCase.calls == [
            UpdateExecuteCall(
                id: id,
                isActive: true,
                name: "Meditar cada día",
                color: "#3A6BC6",
                icon: "leaf",
                frequency: .daily,
                repetitionsPerDay: 1,
                isReminderEnabled: false,
                reminderTime: fixedReminderTime,
                isMutedOnWeekends: false
            )
        ])
    }

    @Test func savingAPausedHabitKeepsItPaused() async {
        let updateUseCase = FakeUpdateHabitUseCase()
        let viewModel = makeViewModel(id: UUID(), isActive: false, name: "Meditar", updateUseCase: updateUseCase)

        await viewModel.save()

        #expect(await updateUseCase.calls.map(\.isActive) == [false])
    }

    @Test func aSuccessfulUpdateMarksDidSaveWithoutError() async {
        let viewModel = makeViewModel(id: UUID(), name: "Meditar")

        await viewModel.save()

        #expect(viewModel.didSave)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func aFailedUpdateShowsTheGenericErrorAndDoesNotMarkDidSave() async {
        let viewModel = makeViewModel(
            id: UUID(),
            name: "Meditar",
            updateUseCase: FakeUpdateHabitUseCase(error: UseCaseFailure())
        )

        await viewModel.save()

        #expect(!viewModel.didSave)
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isLoading)
    }
}
