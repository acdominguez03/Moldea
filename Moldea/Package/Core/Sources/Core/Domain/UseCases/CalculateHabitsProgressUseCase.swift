//
//  CalculateHabitsProgressUseCase.swift
//  Core
//
//  Created by Andrés on 23/09/2026.
//

public protocol CalculateHabitsProgressUseCaseProtocol: Sendable {
    func execute(habits: [TodayHabit], scope: HabitProgressScopeEnum) -> HabitsProgress
}

public struct CalculateHabitsProgressUseCase: CalculateHabitsProgressUseCaseProtocol {
    
    public init() {}
    
    public func execute(habits: [TodayHabit], scope: HabitProgressScopeEnum) -> HabitsProgress {
        let targets = habits.compactMap { todayHabit in
            target(for: todayHabit, scope: scope)
        }
        
        return HabitsProgress(
            completedHabits: targets.count {
                $0.done >= $0.total
            },
            totalHabits: targets.count,
            completedUnits: targets.reduce(0) {
                $0 + $1.done
            },
            totalUnits: targets.reduce(0) {
                $0 + $1.total
            }
        )
    }
    
    private func target(
        for todayHabit: TodayHabit,
        scope: HabitProgressScopeEnum
    ) -> (done: Int, total: Int)? {
        switch scope {
        case .daily:
            let total = max(todayHabit.habit.schedule.repetitionsPerDay, 1)
            return (min(todayHabit.completedToday, total), total)
        case .weekly:
            guard case .weeklyCount(let timesPerWeek) = todayHabit.habit.schedule.frequency else {
                return nil
            }
            let total = max(timesPerWeek, 1) * max(todayHabit.habit.schedule.repetitionsPerDay, 1)
            return (min(todayHabit.completedRepetitionsThisWeek, total), total)
        }
    }
}
