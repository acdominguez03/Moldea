//
//  HabitProgressList.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI
import Core

struct HabitProgressList: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let habits: [TodayHabit]
    let percentage: (TodayHabit) -> Int

    init(habits: [TodayHabit], percentage: @escaping (TodayHabit) -> Int) {
        self.habits = habits
        self.percentage = percentage
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVStack(alignment: .leading, spacing: 16) {
                header
                    .accessibilityAddTraits(.isHeader)

                ForEach(habits) { habitModel in
                    card(for: habitModel)
                    Divider()
                }
            }
            .padding(.top)
        } else {
            List {
                Section {
                    ForEach(habits) { habitModel in
                        card(for: habitModel)
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    header
                }
            }
            .listStyle(.grouped)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
    }

    private var header: some View {
        Text(StatisticsTextsEnum.habitsHeader)
            .font(.headline)
            .fontWeight(.light)
            .textCase(.uppercase)
    }

    private func card(for habitModel: TodayHabit) -> some View {
        HabitProgressCard(
            color: HexColorConverter.color(fromHex: habitModel.habit.color) ?? .gray,
            name: habitModel.habit.name,
            percentage: percentage(habitModel)
        )
    }
}
