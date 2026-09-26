//
//  TodayCardView.swift
//  Today
//
//  Created by Andrés on 23/09/2026.
//
import SwiftUI
import Core

public struct TodayCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var barsWidth: CGFloat = 140

    private let name: String
    private let color: Color
    private let icon: String
    private let schedule: HabitSchedule
    private let completedToday: Int
    private let completedDaysThisWeek: Int
    private let isCompletedToday: Bool
    private let onToggleCompletion: () -> Void

    public init(todayHabit: TodayHabit, onToggleCompletion: @escaping () -> Void) {
        name = todayHabit.habit.name
        color = Self.color(fromHex: todayHabit.habit.color)
        icon = todayHabit.habit.icon
        schedule = todayHabit.habit.schedule
        completedToday = todayHabit.completedToday
        completedDaysThisWeek = todayHabit.completedDaysThisWeek
        isCompletedToday = todayHabit.isCompletedToday
        self.onToggleCompletion = onToggleCompletion
    }

    public var body: some View {
        HStack(spacing: 8) {
            infoLayout {
                HabitIconBadge(color: color, icon: icon)

                VStack(alignment: .leading, spacing: 5) {
                    Text(name)
                        .font(.body)
                        .bold()
                        .strikethrough(isCompletedToday)
                        .foregroundStyle(isCompletedToday ? .secondary : .primary)

                    progress
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue(isCompletedToday ? Text(CoreTextsEnum.accessibilityCompleted) : Text(verbatim: ""))

            Spacer(minLength: 0)

            TodayCompletionCheck(
                name: name,
                completed: completedToday,
                total: repetitionsPerDay,
                color: color,
                action: onToggleCompletion
            )
        }
    }

    private var infoLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
    }

    @ViewBuilder
    private var progress: some View {
        switch schedule.frequency {
        case .daily, .fixedDays:
            subtitle
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .weeklyCount(let timesPerWeek):
            VStack(alignment: .leading, spacing: 6) {
                weeklySubtitle(timesPerWeek: timesPerWeek)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                weeklyBars(timesPerWeek: timesPerWeek)
            }
        }
    }

    private var subtitle: Text {
        guard repetitionsPerDay == 1 else {
            return Text(TodayTextsEnum.progressToday(completedToday, repetitionsPerDay))
        }

        switch HabitScheduleSummaryEnum(schedule: schedule) {
        case .everyDay:
            return Text(CoreTextsEnum.summaryEveryDay)
        case .timesPerDay(let count):
            return Text(CoreTextsEnum.summaryTimesPerDay(count))
        case .weekdays(let symbols):
            return Text(CoreTextsEnum.summaryWeekdays(symbols.formatted()))
                .accessibilityLabel(
                    Text(CoreTextsEnum.summaryWeekdays(HabitScheduleSummaryEnum.weekdayNames(of: schedule).formatted()))
                )
        case .timesPerWeek(let count):
            return Text(CoreTextsEnum.summaryTimesPerWeek(count))
        }
    }

    private func weeklySubtitle(timesPerWeek: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(TodayTextsEnum.progressThisWeek(completedDaysThisWeek, timesPerWeek))

            if repetitionsPerDay > 1 {
                Text(TodayTextsEnum.progressToday(completedToday, repetitionsPerDay))
            }
        }
    }

    private func weeklyBars(timesPerWeek: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<max(timesPerWeek, 1), id: \.self) { index in
                ProgressView(value: fraction(ofDay: index))
                    .progressViewStyle(.linear)
                    .tint(color)
            }
        }
        .frame(maxWidth: barsWidth, alignment: .leading)
        .accessibilityHidden(true)
    }

    private func fraction(ofDay index: Int) -> Double {
        if index < completedDaysThisWeek {
            return 1
        }

        guard index == completedDaysThisWeek, !isCompletedToday else {
            return 0
        }

        return Double(completedToday) / Double(repetitionsPerDay)
    }

    private var repetitionsPerDay: Int {
        max(schedule.repetitionsPerDay, 1)
    }

    private static func color(fromHex hex: String) -> Color {
        HexColorConverter.color(fromHex: hex)
            ?? HexColorConverter.color(fromHex: HabitAppearanceDefaultsEnum.colorHex)
            ?? .gray
    }
}

#Preview {
    List {
        TodayCardView(todayHabit: .preview(name: "Beber agua", frequency: .daily)) {}
        TodayCardView(
            todayHabit: .preview(
                name: "Leer",
                icon: "book",
                color: "#3A6BC6",
                frequency: .daily,
                repetitionsPerDay: 4,
                completedToday: 2
            )
        ) {}
        TodayCardView(
            todayHabit: .preview(
                name: "Meditar",
                icon: "brain.head.profile",
                color: "#7D5BA6",
                frequency: .daily,
                repetitionsPerDay: 2,
                completedToday: 2
            )
        ) {}
        TodayCardView(
            todayHabit: .preview(
                name: "Gimnasio",
                icon: "dumbbell",
                color: "#C8372D",
                frequency: .fixedDays(weekdays: [2, 4, 6])
            )
        ) {}
        TodayCardView(
            todayHabit: .preview(
                name: "Correr",
                icon: "figure.run",
                color: "#6E9440",
                frequency: .weeklyCount(timesPerWeek: 3),
                repetitionsPerDay: 2,
                completedToday: 1,
                completedDays: 1
            )
        ) {}
    }
    .listStyle(.grouped)
}

private extension TodayHabit {
    static func preview(
        name: String,
        icon: String = HabitAppearanceDefaultsEnum.icon,
        color: String = HabitAppearanceDefaultsEnum.colorHex,
        frequency: HabitFrequency,
        repetitionsPerDay: Int = 1,
        completedToday: Int = 0,
        completedDays: Int = 0
    ) -> TodayHabit {
        let calendar = Calendar.current
        let referenceDay = calendar.startOfDay(for: .now)
        let habitID = UUID()

        func completions(on day: Date, count: Int) -> [HabitCompletion] {
            (0..<count).map { repetitionIndex in
                HabitCompletion(
                    id: UUID(),
                    habitID: habitID,
                    day: day,
                    repetitionIndex: repetitionIndex,
                    completedAt: day
                )
            }
        }

        let pastDays = (1...max(completedDays, 1)).prefix(completedDays)
        let past = pastDays.flatMap { offset -> [HabitCompletion] in
            let day = calendar.date(byAdding: .day, value: -offset, to: referenceDay) ?? referenceDay
            return completions(on: day, count: repetitionsPerDay)
        }

        return TodayHabit(
            habit: Habit(
                id: habitID,
                name: name,
                color: color,
                icon: icon,
                isActive: true,
                createdAt: .now,
                updatedAt: .now,
                schedule: HabitSchedule(frequency: frequency, repetitionsPerDay: repetitionsPerDay)
            ),
            completions: past + completions(on: referenceDay, count: completedToday),
            referenceDay: referenceDay
        )
    }
}
