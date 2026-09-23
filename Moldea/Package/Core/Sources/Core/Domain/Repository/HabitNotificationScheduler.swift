//
//  HabitNotificationScheduler.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

public protocol HabitNotificationScheduler: Sendable {
    func scheduleReminder(for habit: Habit) async
    func cancelReminders(for habitID: Habit.ID) async
}
