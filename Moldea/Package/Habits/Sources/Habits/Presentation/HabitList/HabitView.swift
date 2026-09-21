//
//  HabitView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import SwiftUI
import Core

struct HabitView: View {
    let habit: Habit
    let onToggleActive: () -> Void
    let onDelete: () -> Void
    
    private var color: Color {
        HexColorConverter.color(fromHex: habit.color) ?? HabitPaletteColor.gray.color
    }
    
    private var summary: HabitScheduleSummary {
        HabitScheduleSummary(schedule: habit.schedule)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            HabitIconBadge(color: color, icon: habit.icon)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.body)
                    .bold()
                
                subtitle
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onToggleActive) {
                Label(
                    habit.isActive ? HabitsTextsEnum.deactivate : HabitsTextsEnum.activate,
                    systemImage: habit.isActive ? "pause.circle" : "play.circle"
                )
            }
            .tint(habit.isActive ? .orange : .green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label(HabitsTextsEnum.delete, systemImage: "trash")
            }
        }
    }
    
    private var subtitle: Text {
        switch summary {
        case .everyDay:
            Text(HabitsTextsEnum.summaryEveryDay)
        case .timesPerDay(let count):
            Text(HabitsTextsEnum.summaryTimesPerDay(count))
        case .weekdays(let symbols):
            Text("\(HabitsTextsEnum.days): \(symbols.joined(separator: ", "))")
        case .timesPerWeek(let count):
            Text(HabitsTextsEnum.summaryTimesPerWeek(count))
        }
    }
}

#Preview {
    List {
        HabitView(
            habit: .preview(name: "Beber agua", frequency: .daily),
            onToggleActive: {},
            onDelete: {}
        )
        HabitView(
            habit: .preview(name: "Leer", icon: "book", color: "#3A6BC6", frequency: .daily, repetitionsPerDay: 3),
            onToggleActive: {},
            onDelete: {}
        )
        HabitView(
            habit: .preview(name: "Gimnasio", icon: "dumbbell", color: "#C8372D", frequency: .fixedDays(weekdays: [2, 4, 6])),
            onToggleActive: {},
            onDelete: {}
        )
        HabitView(
            habit: .preview(name: "Correr", icon: "figure.run", color: "#6E9440", frequency: .weeklyCount(timesPerWeek: 3)),
            onToggleActive: {},
            onDelete: {}
        )
    }
}

private extension Habit {
    static func preview(
        name: String,
        icon: String = "drop",
        color: String = "#5B6470",
        frequency: HabitFrequency,
        repetitionsPerDay: Int = 1
    ) -> Habit {
        Habit(
            id: UUID(),
            name: name,
            color: color,
            icon: icon,
            isActive: true,
            createdAt: .now,
            updatedAt: .now,
            schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: repetitionsPerDay)
        )
    }
}
