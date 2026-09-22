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
    private let setHabitActiveUseCase: any SetHabitActiveUseCase

    private(set) var isLoading: Bool = false
    private(set) var errorMessage: LocalizedStringResource?
    private(set) var habitToDelete: Habit?
    private(set) var habitToEdit: Habit?

    init(
        deleteHabitUseCase: any DeleteHabitUseCase,
        setHabitActiveUseCase: any SetHabitActiveUseCase
    ) {
        self.deleteHabitUseCase = deleteHabitUseCase
        self.setHabitActiveUseCase = setHabitActiveUseCase
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

    func onHabitClicked(_ habit: Habit) {
        habitToEdit = habit
    }

    func onEditHabitDismissed() {
        habitToEdit = nil
    }

    func onSetHabitActiveClicked(_ habit: Habit) async {
        await perform {
            try await setHabitActiveUseCase.execute(id: habit.id, isActive: !habit.isActive)
        }
    }
}
