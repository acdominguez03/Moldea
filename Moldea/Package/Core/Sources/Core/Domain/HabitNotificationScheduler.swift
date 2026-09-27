//
//  HabitNotificationScheduler.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

public protocol HabitNotificationScheduler: Sendable {
    func scheduleReminder(for habit: Habit) async
    func cancelReminders(for habitID: Habit.ID) async
    func cancelAllReminders() async

    /// Deja las notificaciones pendientes tal y como deberían estar según lo que hay guardado:
    /// una por hábito y día, sin los hábitos pausados, con el aviso apagado o ya completados hoy.
    /// Es idempotente y lee su propio estado, así que se puede llamar tras cualquier cambio.
    func syncReminders() async
}
