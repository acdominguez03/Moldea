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
            VStack(alignment:.leading, spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    HabitIconBadge(color: color, icon: habit.icon)
                    Text(habit.name)
                        .font(.title3.weight(.semibold))
                }
                .padding(16)
                
                Divider()
                
                VStack(spacing: 8) {
                    Toggle(
                        isOn: isReminderEnabledBinding,
                        label: {
                            VStack(alignment: .leading) {
                                Text(SettingsTextsEnum.habitReminderReceiveTitle)
                                    .bold()

                                Text(
                                    habitReminderSheetViewModel.isReminderEnabled
                                        ? SettingsTextsEnum.habitReminderAtTime(
                                            habitReminderSheetViewModel.reminderTime
                                        )
                                        : SettingsTextsEnum.habitReminderDisabled
                                )
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }
                        }
                    )
                    
                    VStack(spacing: 8) {
                        DatePicker(
                            SettingsTextsEnum.habitReminderHourLabel,
                            selection: reminderTimeBinding,
                            displayedComponents: .hourAndMinute
                        )

                        Toggle(
                            isOn: isMutedOnWeekendsBinding,
                            label: {
                                VStack(alignment: .leading) {
                                    Text(SettingsTextsEnum.habitReminderMuteWeekendsTitle)
                                        .font(
                                            .body
                                                .weight(
                                                    habitReminderSheetViewModel.isReminderEnabled ? .bold : .regular
                                                )
                                        )

                                    Text(SettingsTextsEnum.habitReminderMuteWeekendsSubtitle)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        )
                    }
                    .disabled(!habitReminderSheetViewModel.isReminderEnabled)
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle(SettingsTextsEnum.habitReminderSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: SettingsTextsEnum.done)) {
                        Task {
                            await habitReminderSheetViewModel.save()
                            dismiss()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .presentationDetents([.medium])
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
