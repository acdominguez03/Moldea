//
//  NotificationsPicker.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import SwiftUI

struct NotificationsPicker: View {
    let isRemindHabitEnabled: Bool
    let isMutedOnWeekends: Bool
    let reminderTime: Date
    
    let onRemindHabitToggled: (Bool) -> Void
    let onMuteOnWeekendToggled: (Bool) -> Void
    let onReminderTimeChanged: (Date) -> Void
    
    private var isRemindHabitEnabledBinding: Binding<Bool> {
        Binding(get: { isRemindHabitEnabled }, set: { onRemindHabitToggled($0) })
    }
    
    private var isMutedOnWeekendBinding: Binding<Bool> {
        Binding(get: { isMutedOnWeekends }, set: { onMuteOnWeekendToggled($0) })
    }
    
    private var reminderTimeBinding: Binding<Date> {
        Binding(get: { reminderTime }, set: { onReminderTimeChanged($0) })
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(
                isOn: isRemindHabitEnabledBinding,
                label: {
                    VStack(alignment: .leading) {
                        Text(HabitsTextsEnum.remindMeAboutThisHabit)
                            .bold()
                        
                        Text(
                            isRemindHabitEnabled
                                ? HabitsTextsEnum.startingFrom(reminderTime)
                                : HabitsTextsEnum.youWilNotReceiveNotificationsAboutThisHabit
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                },
            )
            .toggleStyle(.switch)
            
            if isRemindHabitEnabled {
                HStack {
                    DatePicker(
                        "Hora",
                        selection: reminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                }
                Toggle(
                    isOn: isMutedOnWeekendBinding,
                    label: {
                        VStack(alignment: .leading) {
                            Text(HabitsTextsEnum.muteOnWeekends)
                                .bold()
                            
                            Text(
                                HabitsTextsEnum.saturdaysAndSundaysWithoutNotifications
                            )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                    }
                )
            }
        }
    }
}


#Preview {
    @Previewable @State var isRemindHabitEnabled: Bool = false
    @Previewable @State var isMutedEnabled: Bool = false
    @Previewable @State var reminderTime: Date = Date()
    
    NotificationsPicker(
        isRemindHabitEnabled: isRemindHabitEnabled,
        isMutedOnWeekends: isMutedEnabled,
        reminderTime: reminderTime,
        onRemindHabitToggled: { isActive in
            isRemindHabitEnabled = !isRemindHabitEnabled
        },
        onMuteOnWeekendToggled: { isActive in
            isMutedEnabled = isActive
        },
        onReminderTimeChanged: { newReminderTime in
            reminderTime = newReminderTime
        }
    )
}
