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

    func selectColor(_ color: Color) {
        selectedColor = color
    }
}
