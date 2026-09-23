//
//  TodayView.swift
//  Today
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Core

public struct TodayView: View {

    @TodayHabitsQuery private var dailyHabits: [TodayHabit]
    @WeeklyHabitsQuery private var weeklyHabits: [TodayHabit]

    @State private var todayViewModel: TodayViewModel
    
    private var selectedTabBinding: Binding<TodayTabEnum> {
        Binding(
            get: { todayViewModel.selectedTab },
            set: { todayViewModel.onTabSelect(newTab: $0) }
        )
    }
    
    public init(habitRepository: any HabitRepository) {
        _todayViewModel = State(
            initialValue: TodayViewModel(
                toggleHabitCompletionUseCase: DefaultToggleHabitCompletionUseCase(
                    repository: habitRepository
                ),
                calculateHabitsProgressUseCase: CalculateHabitsProgressUseCase()
            )
        )
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

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(habits, id: \.id) { todayHabit in
                        TodayCardView(todayHabit: todayHabit) {
                            Task { await todayViewModel.onToggleCompletion(todayHabit) }
                        }
                    }
                } header: {
                    VStack(spacing: 20) {
                        Picker("", selection: selectedTabBinding) {
                            Text("\(TodayTabEnum.daily.title) \(dailyHabits.count)").tag(TodayTabEnum.daily)

                            Text("\(TodayTabEnum.weekly.title) \(weeklyHabits.count)").tag(TodayTabEnum.weekly)
                        }
                        .pickerStyle(.segmented)

                        VStack(spacing: 5) {
                            HStack {
                                Text(
                                    TodayTextsEnum.habitsProgress(
                                        progress.completedHabits,
                                        progress.totalHabits
                                    )
                                )

                                Spacer()

                                Text(
                                    progress.fraction,
                                    format: .percent.precision(.fractionLength(0))
                                )
                                .monospacedDigit()
                            }
                            .font(.footnote)
                            .accessibilityElement(children: .combine)

                            ProgressView(value: progress.fraction)
                                .progressViewStyle(.linear)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
            .listStyle(.grouped)
            .navigationTitle(todayViewModel.selectedTab == .daily ? TodayTextsEnum.screenTitle : TodayTextsEnum.tabWeekly)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    TodayView(
        habitRepository: SwiftDataHabitRepository(
            modelContainer: try! MoldeaSchema.makeModelContainer(inMemory: true)
        )
    )
}
