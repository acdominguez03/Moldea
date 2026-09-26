//
//  HabitFormViewModel.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import Observation
import SwiftUI
import Core

@Observable
@MainActor
final class HabitFormViewModel: BaseViewModel {
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
    private(set) var didSave = false
    
    private let habitID: Habit.ID?
    private let isHabitActive: Bool
    private let createHabitUseCase: any CreateHabitUseCase
    private let updateHabitUseCase: any UpdateHabitUseCase
    
    private(set) var isRemindHabitEnabled: Bool = false
    private(set) var isMutedOnWeekends: Bool = false
    private(set) var reminderTime: Date = defaultReminderTime()

    init(
        id: Habit.ID? = nil,
        isActive: Bool = true,
        name: String = "",
        color: String = HabitPaletteColor.gray.hex,
        icon: String = HabitPaletteIcon.drop.systemName,
        frequency: HabitFrequency = .daily,
        repetitionsPerDay: Int = 1,
        createHabitUseCase: any CreateHabitUseCase,
        updateHabitUseCase: any UpdateHabitUseCase,
        calendar: Calendar = .current,
        isRemindHabitEnabled: Bool = false,
        isMutedOnWeekends: Bool = false,
        reminderTime: Date = defaultReminderTime()
    ) {
        self.habitID = id
        self.isHabitActive = isActive
        self.createHabitUseCase = createHabitUseCase
        self.updateHabitUseCase = updateHabitUseCase
        self.weekdayItems = Self.makeWeekdays(calendar: calendar)
        self.name = name
        self.selectedColorHex = color
        self.selectedIcon = icon
        self.selectedTimesADay = repetitionsPerDay
        
        self.isRemindHabitEnabled = isRemindHabitEnabled
        self.isMutedOnWeekends = isMutedOnWeekends
        self.reminderTime = reminderTime
        

        switch frequency {
        case .daily:
            selectedFrequency = .everyDay
        case .weeklyCount(let timesPerWeek):
            selectedFrequency = .timesPerWeek
            selectedTimesAWeek = timesPerWeek
        case .fixedDays(let weekdays):
            selectedFrequency = .fixedDays
            selectedWeekdays = weekdays
        }
    }

    var isEditing: Bool {
        habitID != nil
    }

    var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDays = selectedFrequency != .fixedDays || !selectedWeekdays.isEmpty
        return hasName && hasDays && !isLoading
    }
    
    func save() async {
        await perform {
            if let habitID {
                try await updateHabitUseCase.execute(
                    id: habitID,
                    isActive: isHabitActive,
                    name: name,
                    color: selectedColorHex,
                    icon: selectedIcon,
                    frequency: makeFrequency(),
                    repetitionsPerDay: selectedTimesADay,
                    isReminderEnabled: isRemindHabitEnabled,
                    reminderTime: reminderTime,
                    isMutedOnWeekends: isMutedOnWeekends
                )
            } else {
                try await createHabitUseCase.execute(
                    name: name,
                    color: selectedColorHex,
                    icon: selectedIcon,
                    frequency: makeFrequency(),
                    repetitionsPerDay: selectedTimesADay,
                    isReminderEnabled: isRemindHabitEnabled,
                    reminderTime: reminderTime,
                    isMutedOnWeekends: isMutedOnWeekends
                )
            }
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
    
    func onRemidHabitToggled(_ isEnabled: Bool) {
        isRemindHabitEnabled = isEnabled
    }
    
    func onMuteOnWeekendToggled(_ isEnabled: Bool) {
        isMutedOnWeekends = isEnabled
    }
    
    func onReminderTimeChanged(_ newReminderTime: Date) {
        reminderTime = newReminderTime
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
    
    public static func defaultReminderTime() -> Date {
        Calendar.current.date(
            bySettingHour: 8,
            minute: 0,
            second: 0,
            of: .now
        ) ?? .now
    }
}
