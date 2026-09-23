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
    let onHabitClicked: () -> Void
    let onSetHabitActiveClicked: () -> Void
    let onDelete: () -> Void
    
    private var color: Color {
        HexColorConverter.color(fromHex: habit.color) ?? HabitPaletteColor.gray.color
    }
    
    private var summary: HabitScheduleSummaryEnum {
        HabitScheduleSummaryEnum(schedule: habit.schedule)
    }
    
    var body: some View {
        Button(action: onHabitClicked) {
            HStack(spacing: 8) {
                HabitIconBadge(color: color, icon: habit.icon)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.body.weight(habit.isActive ? .bold : .regular))
                        .foregroundStyle(habit.isActive ? .primary : .secondary)
                    
                    subtitle
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if(!habit.isActive) {
                    ZStack {
                        Text(HabitsTextsEnum.onPause)
                            .font(.footnote.weight(.semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        .secondary,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onSetHabitActiveClicked) {
                Label(
                    habit.isActive ? HabitsTextsEnum.deactivate : HabitsTextsEnum.activate,
                    systemImage: habit.isActive ? "pause.circle" : "play.circle"
                )
            }
            .tint(habit.isActive ? .orange : .green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: onDelete) {
                Label(HabitsTextsEnum.delete, systemImage: "trash")
            }
            .tint(.red)
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
            onHabitClicked: {},
            onSetHabitActiveClicked: {},
            onDelete: {}
        )
        HabitView(
            habit: .preview(name: "Leer", icon: "book", color: "#3A6BC6", isActive: false, frequency: .daily, repetitionsPerDay: 3),
            onHabitClicked: {},
            onSetHabitActiveClicked: {},
            onDelete: {}
        )
        HabitView(
            habit: .preview(name: "Gimnasio", icon: "dumbbell", color: "#C8372D", frequency: .fixedDays(weekdays: [2, 4, 6])),
            onHabitClicked: {},
            onSetHabitActiveClicked: {},
            onDelete: {}
        )
        HabitView(
            habit: .preview(name: "Correr", icon: "figure.run", color: "#6E9440", frequency: .weeklyCount(timesPerWeek: 3)),
            onHabitClicked: {},
            onSetHabitActiveClicked: {},
            onDelete: {}
        )
    }
}

private extension Habit {
    static func preview(
        name: String,
        icon: String = "drop",
        color: String = "#5B6470",
        isActive: Bool = true,
        frequency: HabitFrequency,
        repetitionsPerDay: Int = 1
    ) -> Habit {
        Habit(
            id: UUID(),
            name: name,
            color: color,
            icon: icon,
            isActive: isActive,
            createdAt: .now,
            updatedAt: .now,
            schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: repetitionsPerDay)
        )
    }
}
