//
//  CreateHabitViewModel.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import Observation
import SwiftUI
import Core

@Observable
@MainActor
final class CreateHabitViewModel: BaseViewModel {
    let timesADayRange = 1...20
    let timesAWeekRange = 1...7
    
    private(set) var selectedColorHex: String = HabitPaletteColor.gray.hex
    private(set) var selectedIcon: String = HabitPaletteIcon.drop.systemName
    private(set) var name: String = ""
    private(set) var selectedFrequency: HabitFrequencyEnum = .everyDay
    private(set) var selectedTimesADay: Int = 1
    private(set) var selectedTimesAWeek: Int = 1
    
    let weekdayItems: [WeekdayItem]
    private(set) var selectedWeekdays: Set<Int> = []
    
    private(set) var isLoading = false
    private(set) var errorMessage: LocalizedStringResource?
    /// Pasa a `true` cuando el hábito se ha guardado; la vista se cierra al observarlo.
    private(set) var didSave = false
    
    private let createHabitUseCase: any CreateHabitUseCase
    
    init(createHabitUseCase: any CreateHabitUseCase, calendar: Calendar = .current) {
        self.createHabitUseCase = createHabitUseCase
        self.weekdayItems = Self.makeWeekdays(calendar: calendar)
    }
    
    /// Comodidad de la interfaz; las reglas de verdad las valida el caso de uso.
    var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDays = selectedFrequency != .fixedDays || !selectedWeekdays.isEmpty
        return hasName && hasDays && !isLoading
    }
    
    func save() async {
        await perform {
            try await createHabitUseCase.execute(
                name: name,
                color: selectedColorHex,
                icon: selectedIcon,
                frequency: makeFrequency(),
                repetitionsPerDay: selectedTimesADay
            )
            didSave = true
        }
    }
    
    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
    
    func setError(_ message: LocalizedStringResource?) {
        errorMessage = message
    }
    
    func onWeekdayToggled(_ weekday: WeekdayItem) {
        if selectedWeekdays.contains(weekday.id) {
            selectedWeekdays.remove(weekday.id)
        } else {
            selectedWeekdays.insert(weekday.id)
        }
    }
    
    var selectedColor: Color {
        HexColorConverter.color(fromHex: selectedColorHex) ?? HabitPaletteColor.gray.color
    }

    func selectColor(hex: String) {
        selectedColorHex = hex
    }
    
    func selectIcon(_ systemName: String) {
        selectedIcon = systemName
    }
    
    func onHabitNameChanged(_ newHabitName: String) {
        name = newHabitName
    }
    
    func onFrequencyChanged(_ frequency: HabitFrequencyEnum) {
        selectedFrequency = frequency
    }
    
    func onIncrementTimeADayClicked() {
        selectedTimesADay = selectedTimesADay + 1
    }
    
    func onDecrementTimeADayClicked() {
        selectedTimesADay = selectedTimesADay - 1
    }
    
    func onIncrementTimesAWeekClicked() {
        selectedTimesAWeek = selectedTimesAWeek + 1
    }
    
    func onDecrementTimesAWeekClicked() {
        selectedTimesAWeek = selectedTimesAWeek - 1
    }
    
    private func makeFrequency() -> HabitFrequency {
        switch selectedFrequency {
        case .everyDay: .daily
        case .timesPerWeek: .weeklyCount(timesPerWeek: selectedTimesAWeek)
        case .fixedDays: .fixedDays(weekdays: selectedWeekdays)
        }
    }
    
    private static func makeWeekdays(calendar: Calendar) -> [WeekdayItem] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let names = calendar.standaloneWeekdaySymbols
        
        return (0..<7).map { offset in
            let index = (calendar.firstWeekday - 1 + offset) % 7
            return WeekdayItem(id: index + 1, symbol: symbols[index], name: names[index])
        }
    }
}
