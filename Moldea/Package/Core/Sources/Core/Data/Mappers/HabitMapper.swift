//
//  HabitMapper.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 21/9/26.
//

import Foundation

enum HabitMappingError: Error, Equatable {
    case missingSchedule(habitID: UUID)
    case missingTimesPerWeek(habitID: UUID)
    case missingFixedWeekdays(habitID: UUID)
}

enum HabitMapper {
    static func toDomain(_ entity: HabitEntity) throws -> Habit {
        guard let schedule = entity.schedule else {
            throw HabitMappingError.missingSchedule(habitID: entity.id)
        }
        return Habit(
            id: entity.id,
            name: entity.name,
            color: entity.color,
            icon: entity.icon,
            isActive: entity.active,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            schedule: HabitSchedule(
                frequency: try frequency(of: schedule, habitID: entity.id),
                repetitionsPerDay: schedule.repetitionsPerDay
            )
        )
    }

    static func makeEntity(from habit: Habit) -> HabitEntity {
        let entity = HabitEntity(
            id: habit.id,
            name: habit.name,
            color: habit.color,
            icon: habit.icon,
            active: habit.isActive,
            createdAt: habit.createdAt,
            updatedAt: habit.updatedAt
        )
        apply(habit.schedule, to: entity)
        return entity
    }

    static func apply(_ schedule: HabitSchedule, to entity: HabitEntity) {
        let scheduleEntity = entity.schedule ?? HabitScheduleEntity(frequencyType: .daily)
        scheduleEntity.repetitionsPerDay = schedule.repetitionsPerDay
        switch schedule.frequency {
        case .daily:
            scheduleEntity.frequencyType = .daily
            scheduleEntity.timesPerWeek = nil
            scheduleEntity.fixedWeekdays = nil
        case .weeklyCount(let timesPerWeek):
            scheduleEntity.frequencyType = .weeklyCount
            scheduleEntity.timesPerWeek = timesPerWeek
            scheduleEntity.fixedWeekdays = nil
        case .fixedDays(let weekdays):
            scheduleEntity.frequencyType = .fixedDays
            scheduleEntity.timesPerWeek = nil
            scheduleEntity.fixedWeekdays = weekdays.sorted()
        }
        entity.schedule = scheduleEntity
    }

    private static func frequency(
        of schedule: HabitScheduleEntity,
        habitID: UUID
    ) throws -> HabitFrequency {
        switch schedule.frequencyType {
        case .daily:
            return .daily
        case .weeklyCount:
            guard let timesPerWeek = schedule.timesPerWeek else {
                throw HabitMappingError.missingTimesPerWeek(habitID: habitID)
            }
            return .weeklyCount(timesPerWeek: timesPerWeek)
        case .fixedDays:
            guard let weekdays = schedule.fixedWeekdays else {
                throw HabitMappingError.missingFixedWeekdays(habitID: habitID)
            }
            return .fixedDays(weekdays: Set(weekdays))
        }
    }
}
