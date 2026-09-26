//
//  HabitReminderRow.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import SwiftUI
import Core

struct HabitReminderRow: View {
    let habit: Habit
    let onReminderToggled: () -> Void
    let onRowTapped: () -> Void
    
    private var color: Color {
        HexColorConverter.color(fromHex: habit.color) ?? .gray
    }
    
    private var isReminderEnabled: Bool {
        habit.reminder?.isEnabled ?? false
    }
    
    private var isReminderEnabledBinding: Binding<Bool> {
        Binding(get: { isReminderEnabled }, set: { _ in onReminderToggled() })
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle(
                isOn: isReminderEnabledBinding,
                label : {
                    Button(action: onRowTapped) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(color)
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(habit.name)
                                
                                if let subtitle {
                                    Text(subtitle)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            )
        }
    }
    
    private var subtitle: String? {
        habit.reminder?.subtitle
    }
}

extension HabitReminder {
    var subtitle: String {
        subtitleComponents.joined(separator: " · ")
    }
    
    private var subtitleComponents: [String] {
        var components = [String(localized: SettingsTextsEnum.habitReminderAtTime(time))]
        
        if isMutedOnWeekends {
            components
                .append(String(localized: SettingsTextsEnum.withoutWeekends))
        }
        
        return components
    }
}

#Preview {
    List {
        HabitReminderRow(
            habit: .preview(name: "Beber 2 L de agua", reminder: HabitReminder(
                time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now,
                isEnabled: false,
                isMutedOnWeekends: false
            )),
            onReminderToggled: {},
            onRowTapped: {}
        )
        HabitReminderRow(
            habit: .preview(name: "Leer", color: "#3A6BC6", reminder: HabitReminder(
                time: Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: .now) ?? .now,
                isEnabled: true,
                isMutedOnWeekends: false
            )),
            onReminderToggled: {},
            onRowTapped: {}
        )
        HabitReminderRow(
            habit: .preview(name: "Gimnasio", color: "#C8372D", reminder: nil),
            onReminderToggled: {},
            onRowTapped: {}
        )
    }
}

private extension Habit {
    static func preview(
        name: String,
        color: String = "#5B6470",
        reminder: HabitReminder?
    ) -> Habit {
        Habit(
            id: UUID(),
            name: name,
            color: color,
            icon: "drop",
            isActive: true,
            createdAt: .now,
            updatedAt: .now,
            schedule: HabitSchedule(frequency: .daily, repetitionsPerDay: 1),
            reminder: reminder
        )
    }
}
