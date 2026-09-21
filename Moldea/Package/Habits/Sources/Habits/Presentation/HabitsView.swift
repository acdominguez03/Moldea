//
//  HabitsView.swift
//  Habits
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Core

public struct HabitsView: View {
    @State private var habitsViewModel: HabitsViewModel
    @State private var isSheetPresented: Bool = false
    @HabitsQuery private var habits: [Habit]
    
    private var isShowingDeleteAlert: Binding<Bool> {
        Binding(
            get: { habitsViewModel.habitToDelete != nil },
            set: { if !$0 { habitsViewModel.onDeleteHabitCancelled() } }
        )
    }
    
    private let createHabitUseCase: any CreateHabitUseCase
    
    public init(habitRepository: any HabitRepository) {
        self.createHabitUseCase = DefaultCreateHabitUseCase(repository: habitRepository)
        _habitsViewModel = State(
            initialValue: HabitsViewModel(
                deleteHabitUseCase: DefaultDeleteHabitUseCase(
                    repository: habitRepository
                )
            )
        )
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView {
                        Label(HabitsTextsEnum.emptyState, systemImage: "checklist")
                    }
                } else {
                    List {
                        ForEach(habits) { habit in
                            HabitView(
                                habit: habit,
                                onToggleActive: {},
                                onDelete: {
                                    habitsViewModel.onDeleteHabitRequested(habit)
                                }
                            )
                        }
                    }
                    .listStyle(.grouped)
                    .alert(
                        HabitsTextsEnum.deleteHabitAlertTitle,
                        isPresented: isShowingDeleteAlert,
                        presenting: habitsViewModel.habitToDelete
                    ) { habit in
                        Button(role: .cancel) {
                            habitsViewModel.onDeleteHabitCancelled()
                        } label: {
                            Text(CoreTextsEnum.cancel)
                        }
                        Button(role: .destructive) {
                            Task { await habitsViewModel.onDeleteHabitConfirmed(habit.id) }
                        } label: {
                            Text(HabitsTextsEnum.confirm)
                        }
                    } message: { habit in
                        Text(
                            HabitsTextsEnum
                                .deleteHabitAlertMessage(habit.name)
                        )
                    }
                }
            }
            .navigationTitle(HabitsTextsEnum.screenTitle)
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isSheetPresented = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isSheetPresented) {
                CreateHabitView(
                    createHabitViewModel: CreateHabitViewModel(createHabitUseCase: createHabitUseCase),
                    iconCatalog: BundleHabitIconCatalog()
                )
            }
        }
    }
}

#Preview {
    HabitsView(
        habitRepository: SwiftDataHabitRepository(
            modelContainer: try! MoldeaSchema.makeModelContainer(inMemory: true)
        )
    )
}
