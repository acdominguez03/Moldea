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
    private(set) var selectedColor: Color = Color.accentColor
    private(set) var selectedIcon: String = HabitPaletteIcon.drop.systemName
    private(set) var name: String = ""

    func selectColor(_ color: Color) {
        selectedColor = color
    }

    func selectIcon(_ systemName: String) {
        selectedIcon = systemName
    }
    
    func onHabitNameChanged(_ newHabitName: String) {
        name = newHabitName
    }
}
