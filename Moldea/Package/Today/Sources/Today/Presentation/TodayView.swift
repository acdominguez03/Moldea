//
//  TodayView.swift
//  Today
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Foundation
import Core

public struct TodayView: View {
    @Environment(\.todayDependencies) private var dependencies
    @Environment(\.scenePhase) private var scenePhase

    @State private var referenceDate: Date = .now

    public init() {}

    public var body: some View {
        if let dependencies {
            TodayContentView(
                viewModel: dependencies.makeTodayViewModel(),
                referenceDate: referenceDate
            )
            .id(referenceDate)
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                refreshReferenceDateIfNeeded()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    refreshReferenceDateIfNeeded()
                }
            }
        } else {
            MissingDependenciesView(TodayDependencies.self)
        }
    }

    private func refreshReferenceDateIfNeeded() {
        let now = Date.now
        if !Calendar.current.isDate(now, inSameDayAs: referenceDate) {
            referenceDate = now
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
    
    init(viewModel: TodayViewModel, referenceDate: Date) {
        _todayViewModel = State(initialValue: viewModel)
        _dailyHabits = TodayHabitsQuery(date: referenceDate)
        _weeklyHabits = WeeklyHabitsQuery(date: referenceDate)
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
