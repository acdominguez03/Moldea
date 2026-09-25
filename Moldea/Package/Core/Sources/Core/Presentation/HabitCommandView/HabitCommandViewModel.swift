//
//  HabitCommandViewModel.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

import Foundation

@Observable
@MainActor
final class HabitCommandViewModel: BaseViewModel {
    private(set) var phase: HabitCommandPhaseEnum = .parsing
    private(set) var isLoading = false
    private(set) var errorMessage: LocalizedStringResource?

    private let parser: any HabitCommandParsing
    private let createHabitUseCase: any CreateHabitUseCase
    private let deleteHabitUseCase: any DeleteHabitUseCase
    private let completeHabitsUseCase: any CompleteHabitsUseCase
    private let getTodayHabitsUseCase: any GetTodayHabitsUseCase

    var availability: LanguageModelAvailabilityEnum { parser.availability }

    var unavailableMessage: LocalizedStringResource? {
        guard case .unavailable(let reason) = availability else { return nil }
        return Self.message(for: reason)
    }

    var shouldAutoDismiss: Bool {
        guard case .done(.completed(_, let alreadyCompleted)) = phase else { return false }
        return alreadyCompleted.isEmpty
    }

    init(
        parser: any HabitCommandParsing,
        createHabitUseCase: any CreateHabitUseCase,
        deleteHabitUseCase: any DeleteHabitUseCase,
        completeHabitsUseCase: any CompleteHabitsUseCase,
        getTodayHabitsUseCase: any GetTodayHabitsUseCase
    ) {
        self.parser = parser
        self.createHabitUseCase = createHabitUseCase
        self.deleteHabitUseCase = deleteHabitUseCase
        self.completeHabitsUseCase = completeHabitsUseCase
        self.getTodayHabitsUseCase = getTodayHabitsUseCase
    }

    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func setError(_ message: LocalizedStringResource?) {
        errorMessage = message
    }

    func handle(transcript: String, knownHabits: [Habit]) async {
        errorMessage = nil
        phase = .parsing

        guard case .available = availability else { return }

        do {
            let todayHabits = try await getTodayHabitsUseCase.execute(on: .now)
            phase = try await resolve(
                transcript: transcript,
                knownHabits: knownHabits,
                todayHabits: todayHabits
            )
        } catch is CancellationError {
        } catch let error as HabitCommandErrorEnum {
            fail(with: Self.message(for: error))
        } catch let error as LanguageModelErrorEnum {
            fail(with: Self.message(for: error))
        } catch {
            fail(with: CoreTextsEnum.genericError)
        }
    }

    func confirm() async {
        switch phase {
        case .confirmingCreate(let draft):
            await perform {
                try await createHabitUseCase.execute(
                    name: draft.name,
                    color: HabitAppearanceDefaultsEnum.colorHex,
                    icon: HabitAppearanceDefaultsEnum.icon,
                    frequency: draft.frequency,
                    repetitionsPerDay: draft.repetitionsPerDay
                )
            }
            if errorMessage == nil {
                phase = .done(.created(draft))
            }
        case .confirmingDelete(let habit):
            await perform {
                try await deleteHabitUseCase.execute(id: habit.id)
            }
            if errorMessage == nil {
                phase = .done(.deleted(habit))
            }
        case .parsing, .done, .failed:
            break
        }
    }

    private func resolve(
        transcript: String,
        knownHabits: [Habit],
        todayHabits: [TodayHabit]
    ) async throws -> HabitCommandPhaseEnum {
        let command = try await parser.parseCommand(
            in: transcript,
            from: knownHabits,
            today: todayHabits
        )

        switch command {
        case .create(let draft):
            return .confirmingCreate(draft)
        case .delete(let habitID):
            guard let habit = knownHabits.first(where: { $0.id == habitID }) else {
                throw HabitCommandErrorEnum.habitNotFound
            }
            return .confirmingDelete(habit)
        case .complete(let habitIDs):
            let habits = todayHabits.map(\.habit)
            let mentioned = habitIDs.filter { id in habits.contains { $0.id == id } }

            guard !mentioned.isEmpty else {
                throw HabitCommandErrorEnum.noHabitsMentioned
            }

            let result = try await completeHabitsUseCase.execute(
                habitIDs: mentioned,
                in: todayHabits
            )
            return .done(
                .completed(
                    completed: Self.habits(result.completed, in: habits),
                    alreadyCompleted: Self.habits(result.alreadyCompleted, in: habits)
                )
            )
        }
    }

    private static func habits(_ ids: [Habit.ID], in habits: [Habit]) -> [Habit] {
        ids.compactMap { id in habits.first { $0.id == id } }
    }

    private func fail(with message: LocalizedStringResource) {
        errorMessage = message
        phase = .failed
    }

    // MARK: - Error descriptions

    private static func message(for reason: LanguageModelUnavailableReasonEnum) -> LocalizedStringResource {
        switch reason {
        case .deviceNotEligible: CoreTextsEnum.aiErrorDeviceNotEligible
        case .appleIntelligenceNotEnabled: CoreTextsEnum.aiErrorNotEnabled
        case .modelNotReady: CoreTextsEnum.aiErrorModelNotReady
        case .localeNotSupported: CoreTextsEnum.aiErrorLocaleNotSupported
        case .unknown: CoreTextsEnum.aiErrorUnavailableUnknown
        }
    }

    private static func message(for error: HabitCommandErrorEnum) -> LocalizedStringResource {
        switch error {
        case .notUnderstood: CoreTextsEnum.aiErrorNotUnderstood
        case .habitNotFound: CoreTextsEnum.aiErrorHabitNotFound
        case .noHabitsMentioned: CoreTextsEnum.aiNoHabitsRecognized
        case .missingFrequencyData, .schemaFailed: CoreTextsEnum.aiErrorInvalidCommand
        }
    }

    private static func message(for error: LanguageModelErrorEnum) -> LocalizedStringResource {
        switch error {
        case .sessionUnavailable: CoreTextsEnum.aiErrorSessionUnavailable
        case .assetsUnavailable: CoreTextsEnum.aiErrorAssetsUnavailable
        case .modelLoadFailed: CoreTextsEnum.aiErrorModelLoadFailed
        case .guardrailViolation: CoreTextsEnum.aiErrorGuardrailViolation
        case .refusal: CoreTextsEnum.aiErrorRefusal
        case .contextSizeExceeded: CoreTextsEnum.aiErrorContextSizeExceeded
        case .rateLimited: CoreTextsEnum.aiErrorRateLimited
        case .localeNotSupported: CoreTextsEnum.aiErrorLocaleNotSupported
        case .unsupportedCapability: CoreTextsEnum.aiErrorUnsupportedCapability
        case .generationFailed: CoreTextsEnum.aiErrorGenerationFailed
        }
    }
}
