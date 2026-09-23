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
    
    private var habitToEdit: Binding<Habit?> {
        Binding(
            get: { habitsViewModel.habitToEdit },
            set: { if $0 == nil { habitsViewModel.onEditHabitDismissed() } }
        )
    }

    private let createHabitUseCase: any CreateHabitUseCase
    private let updateHabitUseCase: any UpdateHabitUseCase

    public init(habitRepository: any HabitRepository) {
        self.createHabitUseCase = DefaultCreateHabitUseCase(repository: habitRepository)
        self.updateHabitUseCase = DefaultUpdateHabitUseCase(repository: habitRepository)
        _habitsViewModel = State(
            initialValue: HabitsViewModel(
                deleteHabitUseCase: DefaultDeleteHabitUseCase(
                    repository: habitRepository
                ),
                setHabitActiveUseCase: DefaultSetHabitActiveUseCase(
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
                        Section {
                            ForEach(habits) { habit in
                                HabitView(
                                    habit: habit,
                                    onHabitClicked: {
                                        habitsViewModel.onHabitClicked(habit)
                                    },
                                    onSetHabitActiveClicked: {
                                        Task { await habitsViewModel.onSetHabitActiveClicked(habit) }
                                    },
                                    onDelete: {
                                        habitsViewModel.onDeleteHabitRequested(habit)
                                    }
                                )
                            }
                        } footer: {
                            if habits.count < 3 {
                                Text(HabitsTextsEnum.habitGuidance)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
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
                HabitFormView(
                    habitFormViewModel: HabitFormViewModel(
                        createHabitUseCase: createHabitUseCase,
                        updateHabitUseCase: updateHabitUseCase
                    ),
                    iconCatalog: BundleHabitIconCatalog()
                )
            }
            .sheet(item: habitToEdit) { habit in
                HabitFormView(
                    habitFormViewModel: HabitFormViewModel(
                        id: habit.id,
                        name: habit.name,
                        color: habit.color,
                        icon: habit.icon,
                        frequency: habit.schedule.frequency,
                        repetitionsPerDay: habit.schedule.repetitionsPerDay,
                        createHabitUseCase: createHabitUseCase,
                        updateHabitUseCase: updateHabitUseCase,
                        isRemindHabitEnabled: habit.reminder?.isEnabled ?? false,
                        isMutedOnWeekends: habit.reminder?.isMutedOnWeekends ?? false,
                        reminderTime: habit.reminder?.time ?? HabitFormViewModel
                            .defaultReminderTime()
                    ),
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
