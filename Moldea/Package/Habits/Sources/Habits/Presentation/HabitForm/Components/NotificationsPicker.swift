//
//  NotificationsPicker.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 22/9/26.
//

import SwiftUI
import Core

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
        Section {
            Toggle(HabitsTextsEnum.remindMeAboutThisHabit, isOn: isRemindHabitEnabledBinding)

            if isRemindHabitEnabled {
                DatePicker(
                    HabitsTextsEnum.hour,
                    selection: reminderTimeBinding,
                    displayedComponents: .hourAndMinute
                )

                Toggle(HabitsTextsEnum.muteOnWeekends, isOn: isMutedOnWeekendBinding)
            }
        } header: {
            Text(CoreTextsEnum.announcements)
        } footer: {
            VStack(alignment: .leading) {
                if isRemindHabitEnabled {
                    Text(HabitsTextsEnum.startingFrom(reminderTime))

                    if isMutedOnWeekends {
                        Text(HabitsTextsEnum.saturdaysAndSundaysWithoutNotifications)
                    }
                } else {
                    Text(HabitsTextsEnum.youWilNotReceiveNotificationsAboutThisHabit)
                }
            }
        }
    }
}


#Preview {
    @Previewable @State var isRemindHabitEnabled: Bool = false
    @Previewable @State var isMutedEnabled: Bool = false
    @Previewable @State var reminderTime: Date = Date()

    Form {
        NotificationsPicker(
            isRemindHabitEnabled: isRemindHabitEnabled,
            isMutedOnWeekends: isMutedEnabled,
            reminderTime: reminderTime,
            onRemindHabitToggled: { isRemindHabitEnabled = $0 },
            onMuteOnWeekendToggled: { isMutedEnabled = $0 },
            onReminderTimeChanged: { reminderTime = $0 }
        )
    }
}
