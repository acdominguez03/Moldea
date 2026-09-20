//
//  CreateHabitViewModel.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import Observation
import SwiftUI

@Observable
@MainActor
final class CreateHabitViewModel {
    let timesADayRange = 1...20
    let timesAWeekRange = 1...7
    
    private(set) var selectedColor: Color = Color.accentColor
    private(set) var selectedIcon: String = HabitPaletteIcon.drop.systemName
    private(set) var name: String = ""
    private(set) var selectedFrequency: HabitFrequencyEnum = .everyDay
    private(set) var selectedTimesADay: Int = 1
    private(set) var selectedTimesAWeek: Int = 1
    
    let weekdayItems: [WeekdayItem]
    private(set) var selectedWeekdays: Set<Int> = []
    
    init(calendar: Calendar = .current) {
        self.weekdayItems = Self.makeWeekdays(calendar: calendar)
    }
    
    func onWeekdayToggled(_ weekday: WeekdayItem) {
        if selectedWeekdays.contains(weekday.id) {
            selectedWeekdays.remove(weekday.id)
        } else {
            selectedWeekdays.insert(weekday.id)
        }
    }
    
    func selectColor(_ color: Color) {
        selectedColor = color
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
    
    private static func makeWeekdays(calendar: Calendar) -> [WeekdayItem] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let names = calendar.standaloneWeekdaySymbols
        
        return (0..<7).map { offset in
            let index = (calendar.firstWeekday - 1 + offset) % 7
            return WeekdayItem(id: index + 1, symbol: symbols[index], name: names[index])
        }
    }
}
