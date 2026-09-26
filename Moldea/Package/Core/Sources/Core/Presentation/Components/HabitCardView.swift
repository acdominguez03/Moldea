//
//  HabitCardView.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

import SwiftUI

public struct HabitCardView: View {
    private let name: String
    private let color: Color
    private let icon: String
    private let schedule: HabitSchedule

    public init(habit: Habit) {
        name = habit.name
        color = Self.color(fromHex: habit.color)
        icon = habit.icon
        schedule = habit.schedule
    }

    public init(draft: NewHabitDraft) {
        name = draft.name
        color = Self.color(fromHex: HabitAppearanceDefaultsEnum.colorHex)
        icon = HabitAppearanceDefaultsEnum.icon
        schedule = HabitSchedule(
            frequency: draft.frequency,
            repetitionsPerDay: draft.repetitionsPerDay
        )
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))

        layout {
            HabitIconBadge(color: color, icon: icon)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .bold()

                subtitle
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: Text {
        switch HabitScheduleSummaryEnum(schedule: schedule) {
        case .everyDay:
            Text(CoreTextsEnum.summaryEveryDay)
        case .timesPerDay(let count):
            Text(CoreTextsEnum.summaryTimesPerDay(count))
        case .weekdays(let symbols):
            Text(CoreTextsEnum.summaryWeekdays(symbols.formatted()))
                .accessibilityLabel(
                    Text(CoreTextsEnum.summaryWeekdays(HabitScheduleSummaryEnum.weekdayNames(of: schedule).formatted()))
                )
        case .timesPerWeek(let count):
            Text(CoreTextsEnum.summaryTimesPerWeek(count))
        }
    }

    private static func color(fromHex hex: String) -> Color {
        HexColorConverter.color(fromHex: hex)
            ?? HexColorConverter.color(fromHex: HabitAppearanceDefaultsEnum.colorHex)
            ?? .gray
    }
}

#Preview {
    VStack(spacing: 16) {
        HabitCardView(habit: .preview(name: "Beber agua", frequency: .daily))
        HabitCardView(
            habit: .preview(name: "Leer", icon: "book", color: "#3A6BC6", frequency: .daily, repetitionsPerDay: 3)
        )
        HabitCardView(
            habit: .preview(name: "Gimnasio", icon: "dumbbell", color: "#C8372D", frequency: .fixedDays(weekdays: [2, 4, 6]))
        )
        HabitCardView(
            habit: .preview(name: "Correr", icon: "figure.run", color: "#6E9440", frequency: .weeklyCount(timesPerWeek: 3))
        )
        HabitCardView(
            draft: NewHabitDraft(name: "Meditar", frequency: .fixedDays(weekdays: [2, 6]), repetitionsPerDay: 1)
        )
    }
    .padding()
}

private extension Habit {
    static func preview(
        name: String,
        icon: String = HabitAppearanceDefaultsEnum.icon,
        color: String = HabitAppearanceDefaultsEnum.colorHex,
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
