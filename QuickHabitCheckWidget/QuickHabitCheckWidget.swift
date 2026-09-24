//
//  QuickHabitCheckWidget.swift
//  QuickHabitCheckWidget
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import WidgetKit
import AppIntents
import SwiftUI
import Core

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> QuickHabitEntry {
        QuickHabitEntry(date: .now, habits: [])
    }
    
    func getSnapshot(
        in context: Context,
        completion: @escaping @Sendable (QuickHabitEntry) -> Void
    ) {
        Task {
            completion(QuickHabitEntry(date: .now, habits: await todayHabits()))
        }
    }
    
    func getTimeline(
        in context: Context,
        completion: @escaping @Sendable (Timeline<QuickHabitEntry>) -> Void
    ) {
        Task {
            let calendar = Calendar.current
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
            let midnight = calendar.startOfDay(for: tomorrow)
            
            completion(
                Timeline(
                    entries: [QuickHabitEntry(date: .now, habits: await todayHabits())],
                    policy: .after(midnight)
                )
            )
        }
    }
    
    private func todayHabits() async -> [TodayHabit] {
        guard let container = try? MoldeaSchema.makeModelContainer() else {
            return []
        }
        let useCase = DefaultGetTodayHabitsUseCase(
            repository: SwiftDataTodayHabitsRepository(modelContainer: container)
        )
        return (try? await useCase.execute(on: .now)) ?? []
    }
}

struct QuickHabitEntry: TimelineEntry {
    let date: Date
    let habits: [TodayHabit]
}

struct QuickHabitCheckWidgetEntryView: View {
    var entry: Provider.Entry
    
    private var completedHabits: Int {
        entry.habits.count { habit in
            habit.isCompletedToday == true
        }
    }
    
    private var habits: [TodayHabit] {
        entry.habits.filter { !$0.isCompletedToday } + entry.habits.filter { $0.isCompletedToday }
    }
    
    var body: some View {
        if habits.isEmpty {
            VStack (spacing: 8) {
                Image(systemName: "calendar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.secondary)
                
                Text(CoreTextsEnum.noHabitsForToday)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            ViewThatFits(in: .vertical) {
                ForEach((1...habits.count).reversed(), id: \.self) { count in
                    content(showing: count)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
    
    private var header: some View {
        HStack {
            Text(CoreTextsEnum.quickCheck)
                .font(.caption2)
                .textCase(.uppercase)
            
            Spacer()
            
            Text("\(completedHabits)/\(entry.habits.count)")
                .font(.caption2)
        }
        .padding(.bottom, 4)
    }
    
    private func content(showing count: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            ForEach(habits.prefix(count)) { todayHabit in
                HabitRow(todayHabit: todayHabit)
                    .frame(maxHeight: .infinity)
            }
            
            if count < habits.count {
                Text("+\(habits.count - count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct HabitRow: View {
    let todayHabit: TodayHabit
    
    private var color: Color {
        HexColorConverter.color(fromHex: todayHabit.habit.color) ?? .gray
    }
    
    private var total: Int {
        max(todayHabit.habit.schedule.repetitionsPerDay, 1)
    }
    
    var body: some View {
        Button(intent: ToggleHabitIntent(habitID: todayHabit.id)) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: todayHabit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(color)
                    
                    Text(todayHabit.habit.name)
                        .font(.subheadline)
                        .strikethrough(todayHabit.isCompletedToday)
                        .foregroundStyle(todayHabit.isCompletedToday ? .secondary : .primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if total > 1 {
                        Text("\(todayHabit.completedToday)/\(total)")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
                .frame(maxHeight: .infinity)
                
                Divider()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct QuickHabitCheckWidget: Widget {
    let kind: String = "QuickHabitCheckWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuickHabitCheckWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(CoreTextsEnum.quickCheck)
        .description(CoreTextsEnum.habitsPlannedForToday)
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
