//
//  HabitsViewModel.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Observation
import SwiftUI
import Core

@Observable
@MainActor
final class HabitsViewModel: BaseViewModel {
    private let deleteHabitUseCase: any DeleteHabitUseCase
    
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: LocalizedStringResource?
    private(set) var habitToDelete: Habit?
    
    init(deleteHabitUseCase: any DeleteHabitUseCase) {
        self.deleteHabitUseCase = deleteHabitUseCase
    }
    
    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
    
    func setError(_ message: LocalizedStringResource?) {
        errorMessage = message
    }
    
    func onDeleteHabitRequested(_ habit: Habit) {
        habitToDelete = habit
    }

    func onDeleteHabitCancelled() {
        habitToDelete = nil
    }

    func onDeleteHabitConfirmed(_ habitId: Habit.ID) async {
        habitToDelete = nil
        await perform {
            try await deleteHabitUseCase.execute(id: habitId)
        }
    }
}
