//
//  HabitView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import SwiftUI
import Core

struct HabitItemView: View {
    let habit: Habit
    let onHabitClicked: () -> Void
    let onSetHabitActiveClicked: () -> Void
    let onDelete: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var color: Color {
        HexColorConverter.color(fromHex: habit.color) ?? HabitPaletteColorEnum.gray.color
    }
    
    private var summary: HabitScheduleSummaryEnum {
        HabitScheduleSummaryEnum(schedule: habit.schedule)
    }
    
    var body: some View {
        Button(action: onHabitClicked) {
            layout {
                HabitIconBadge(color: color, icon: habit.icon)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .foregroundStyle(habit.isActive ? .primary : .secondary)

                    subtitle
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer()
                }

                if !habit.isActive {
                    Text(HabitsTextsEnum.onPause)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: Text(activeToggleTitle), onSetHabitActiveClicked)
        .accessibilityAction(named: Text(HabitsTextsEnum.delete), onDelete)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onSetHabitActiveClicked) {
                activeToggleLabel
            }
            .tint(habit.isActive ? .orange : .green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label(HabitsTextsEnum.delete, systemImage: "trash")
            }
        }
        .contextMenu {
            Button(action: onHabitClicked) {
                Label(HabitsTextsEnum.edit, systemImage: "pencil")
            }
            Button(action: onSetHabitActiveClicked) {
                activeToggleLabel
            }
            Button(role: .destructive, action: onDelete) {
                Label(HabitsTextsEnum.delete, systemImage: "trash")
            }
        }
    }

    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
    }

    private var activeToggleTitle: LocalizedStringResource {
        habit.isActive ? HabitsTextsEnum.deactivate : HabitsTextsEnum.activate
    }

    private var activeToggleLabel: some View {
        Label(activeToggleTitle, systemImage: habit.isActive ? "pause" : "play")
    }

    private var subtitle: Text {
        switch summary {
        case .everyDay:
            Text(HabitsTextsEnum.summaryEveryDay)
        case .timesPerDay(let count):
            Text(HabitsTextsEnum.summaryTimesPerDay(count))
        case .weekdays(let symbols):
            Text(CoreTextsEnum.summaryWeekdays(symbols.formatted()))
                .accessibilityLabel(
                    Text(CoreTextsEnum.summaryWeekdays(HabitScheduleSummaryEnum.weekdayNames(of: habit.schedule).formatted()))
                )
        case .timesPerWeek(let count):
            Text(HabitsTextsEnum.summaryTimesPerWeek(count))
        }
    }
}

#Preview {
    List {
        HabitItemView(
            habit: .preview(name: "Beber agua", frequency: .daily),
            onHabitClicked: {},
            onSetHabitActiveClicked: {},
            onDelete: {}
        )
        HabitItemView(
            habit: .preview(name: "Leer", icon: "book", color: "#3A6BC6", isActive: false, frequency: .daily, repetitionsPerDay: 3),
            onHabitClicked: {},
            onSetHabitActiveClicked: {},
            onDelete: {}
        )
        HabitItemView(
            habit: .preview(name: "Gimnasio", icon: "dumbbell", color: "#C8372D", frequency: .fixedDays(weekdays: [2, 4, 6])),
            onHabitClicked: {},
            onSetHabitActiveClicked: {},
            onDelete: {}
        )
        HabitItemView(
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
