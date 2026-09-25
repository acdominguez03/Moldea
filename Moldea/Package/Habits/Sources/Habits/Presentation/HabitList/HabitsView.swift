//
//  HabitsView.swift
//  Habits
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Core

public struct HabitsView: View {
    @Environment(\.habitsDependencies) private var dependencies

    public init() {}

    public var body: some View {
        HabitsContentView(viewModel: dependencies.makeHabitsViewModel())
    }
}

struct HabitsContentView: View {
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

    init(viewModel: HabitsViewModel) {
        _habitsViewModel = State(initialValue: viewModel)
    }

    var body: some View {
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
                HabitFormView()
            }
            .sheet(item: habitToEdit) { habit in
                HabitFormView(editing: habit)
            }
        }
    }
}

#Preview(traits: .moldea) {
    HabitsView()
}
