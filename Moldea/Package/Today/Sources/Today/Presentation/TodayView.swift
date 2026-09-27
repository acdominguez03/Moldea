//
//  TodayView.swift
//  Today
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Core

public struct TodayView: View {
    @Environment(\.todayDependencies) private var dependencies

    public init() {}

    public var body: some View {
        if let dependencies {
            TodayContentView(viewModel: dependencies.makeTodayViewModel())
        } else {
            MissingDependenciesView(TodayDependencies.self)
        }
    }
}

struct TodayContentView: View {

    @TodayHabitsQuery private var dailyHabits: [TodayHabit]
    @WeeklyHabitsQuery private var weeklyHabits: [TodayHabit]

    @State private var todayViewModel: TodayViewModel
    
    private var selectedTabBinding: Binding<TodayTabEnum> {
        Binding(
            get: { todayViewModel.selectedTab },
            set: { todayViewModel.onTabSelect(newTab: $0) }
        )
    }
    
    private var isShowingError: Binding<Bool> {
        Binding(
            get: { todayViewModel.errorMessage != nil },
            set: { if !$0 { todayViewModel.onErrorDismissed() } }
        )
    }

    init(viewModel: TodayViewModel) {
        _todayViewModel = State(initialValue: viewModel)
    }

    private var habits: [TodayHabit] {
        switch todayViewModel.selectedTab {
        case .daily:
            dailyHabits
        case .weekly:
            weeklyHabits
        }
    }

    private var progress: HabitsProgress {
        todayViewModel.progress(for: habits)
    }

    private var dailyProgress: HabitsProgress {
        todayViewModel.dailyProgress(for: dailyHabits)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(TodayTextsEnum.tabPickerLabel, selection: selectedTabBinding) {
                        ForEach(TodayTabEnum.allCases, id: \.self) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                Section {
                    ProgressView(value: progress.fraction) {
                        Text(
                            TodayTextsEnum.habitsProgress(
                                progress.completedHabits,
                                progress.totalHabits
                            )
                        )
                    } currentValueLabel: {
                        Text(
                            progress.fraction,
                            format: .percent.precision(.fractionLength(0))
                        )
                    }
                }

                Section {
                    if habits.isEmpty {
                        Text(TodayTextsEnum.emptyState)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(habits, id: \.id) { todayHabit in
                        TodayCardView(todayHabit: todayHabit) {
                            Task { await todayViewModel.onToggleCompletion(todayHabit) }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(todayViewModel.selectedTab == .daily ? TodayTextsEnum.screenTitle : TodayTextsEnum.tabWeekly)
            .navigationBarTitleDisplayMode(.large)
            .alert(TodayTextsEnum.errorTitle, isPresented: isShowingError) {
            } message: {
                if let errorMessage = todayViewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: dailyProgress, initial: true) {
                todayViewModel.publishDailyProgress(for: dailyHabits)
            }
        }
    }
}

#Preview(traits: .moldea) {
    TodayView()
        .environment(\.todayDependencies, .preview)
}
