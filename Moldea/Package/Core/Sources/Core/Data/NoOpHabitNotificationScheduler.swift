//
//  NoOpHabitNotificationScheduler.swift
//  Core
//

/// Para procesos que no pueden gestionar las notificaciones de la app, como la extensión del
/// widget: un intent de widget se ejecuta por defecto en el proceso de la extensión, y de si allí
/// se comparten las notificaciones pendientes con la app la documentación de Apple no dice nada.
/// No hace nada; la siguiente sincronización desde la app deja las pendientes al día.
public struct NoOpHabitNotificationScheduler: HabitNotificationScheduler {
    public init() {}

    public func scheduleReminder(for habit: Habit) async {}
    public func cancelReminders(for habitID: Habit.ID) async {}
    public func cancelAllReminders() async {}
    public func syncReminders() async {}
}
