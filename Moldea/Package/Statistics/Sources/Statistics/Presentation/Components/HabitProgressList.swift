//
//  HabitProgressList.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI
import Core

struct HabitProgressList: View {
    let habits: [TodayHabit]
    let percentage: (TodayHabit) -> Int

    init(habits: [TodayHabit], percentage: @escaping (TodayHabit) -> Int) {
        self.habits = habits
        self.percentage = percentage
    }

    var body: some View {
        List {
            Section {
                ForEach(habits) { habitModel in
                    HabitProgressCard(
                        color: HexColorConverter.color(fromHex: habitModel.habit.color) ?? .gray,
                        name: habitModel.habit.name,
                        percentage: percentage(habitModel)
                    )
                    .listRowBackground(Color.clear)
                }
            } header: {
                Text(StatisticsTextsEnum.habitsHeader)
                    .font(.headline)
                    .fontWeight(.light)
                    .textCase(.uppercase)
            }
        }
        .listStyle(.grouped)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }
}
