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
    private(set) var selectedColor: Color? = nil
    private(set) var selectedIcon: String = HabitPaletteIcon.drop.systemName

    func selectColor(_ color: Color) {
        selectedColor = color
    }

    func selectIcon(_ systemName: String) {
        selectedIcon = systemName
    }
}
