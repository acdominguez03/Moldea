//
//  HabitReminderSheet.swift
//  Settings
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import SwiftUI
import Core

struct HabitReminderSheet: View {
    let habit: Habit
    @State var habitReminderSheetViewModel: HabitReminderSheetViewModel
    @Environment(\.dismiss) private var dismiss
    
    private var color: Color {
        HexColorConverter.color(fromHex: habit.color) ?? .gray
    }
    
    private var isReminderEnabledBinding: Binding<Bool> {
        Binding(
            get: { habitReminderSheetViewModel.isReminderEnabled },
            set: { habitReminderSheetViewModel.onRemindHabitToggled($0) }
        )
    }
    
    private var isMutedOnWeekendsBinding: Binding<Bool> {
        Binding(
            get: { habitReminderSheetViewModel.isMutedOnWeekends },
            set: { habitReminderSheetViewModel.onMuteOnWeekendToggled($0) }
        )
    }
    
    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { habitReminderSheetViewModel.reminderTime },
            set: { habitReminderSheetViewModel.onReminderTimeChanged($0) }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        HabitIconBadge(color: color, icon: habit.icon, style: .solid)
                        Text(habit.name)
                            .font(.title3.weight(.semibold))
                    }
                }

                Section {
                    Toggle(SettingsTextsEnum.habitReminderReceiveTitle, isOn: isReminderEnabledBinding)

                    Group {
                        DatePicker(
                            SettingsTextsEnum.habitReminderHourLabel,
                            selection: reminderTimeBinding,
                            displayedComponents: .hourAndMinute
                        )

                        Toggle(
                            SettingsTextsEnum.habitReminderMuteWeekendsTitle,
                            isOn: isMutedOnWeekendsBinding
                        )
                    }
                    .disabled(!habitReminderSheetViewModel.isReminderEnabled)
                } footer: {
                    VStack(alignment: .leading) {
                        if habitReminderSheetViewModel.isReminderEnabled {
                            Text(SettingsTextsEnum.habitReminderAtTime(habitReminderSheetViewModel.reminderTime))

                            if habitReminderSheetViewModel.isMutedOnWeekends {
                                Text(SettingsTextsEnum.habitReminderMuteWeekendsSubtitle)
                            }
                        } else {
                            Text(SettingsTextsEnum.habitReminderDisabled)
                        }
                    }
                }
            }
            .navigationTitle(SettingsTextsEnum.habitReminderSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(CoreTextsEnum.cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await habitReminderSheetViewModel.save()
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accentColor)
                    .accessibilityLabel(SettingsTextsEnum.done)
                }
            }
        }
    }
}

#Preview {
    HabitReminderSheet(
        habit: Habit(
            id: UUID(),
            name: "Beber 2 L de agua",
            color: "#3A8FD6",
            icon: "drop",
            isActive: true,
            createdAt: .now,
            updatedAt: .now,
            schedule: HabitSchedule(frequency: .daily, repetitionsPerDay: 4),
            reminder: HabitReminder(
                time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now,
                isEnabled: false,
                isMutedOnWeekends: true
            )
        ),
        habitReminderSheetViewModel: HabitReminderSheetViewModel(
            habit: .init(
                id: UUID(),
                name: "Beber 2 L de agua",
                color: "#3A8FD6",
                icon: "drop",
                isActive: true,
                createdAt: .now,
                updatedAt: .now,
                schedule: HabitSchedule(frequency: .daily, repetitionsPerDay: 4)
            ),
            updateHabitReminderUseCase: PreviewUpdateHabitReminderUseCase()
        )
    )
}

private struct PreviewUpdateHabitReminderUseCase: UpdateHabitReminderUseCase {
    func execute(habit: Habit, isReminderEnabled: Bool, reminderTime: Date, isMutedOnWeekends: Bool) async throws {}
}
