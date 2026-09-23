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
    private let recognizer: any HabitCompletionRecognizing
    private let createHabitUseCase: any CreateHabitUseCase
    private let deleteHabitUseCase: any DeleteHabitUseCase

    var availability: LanguageModelAvailabilityEnum { parser.availability }

    var unavailableMessage: LocalizedStringResource? {
        guard case .unavailable(let reason) = availability else { return nil }
        return Self.message(for: reason)
    }

    var shouldAutoDismiss: Bool {
        guard case .recognized(let habits) = phase else { return false }
        return !habits.isEmpty
    }

    init(
        parser: any HabitCommandParsing,
        recognizer: any HabitCompletionRecognizing,
        createHabitUseCase: any CreateHabitUseCase,
        deleteHabitUseCase: any DeleteHabitUseCase
    ) {
        self.parser = parser
        self.recognizer = recognizer
        self.createHabitUseCase = createHabitUseCase
        self.deleteHabitUseCase = deleteHabitUseCase
    }

    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func setError(_ message: LocalizedStringResource?) {
        errorMessage = message
    }

    func handle(transcript: String, knownHabits: [Habit]) async {
        guard phase != .recognizing else { return }

        errorMessage = nil
        phase = .parsing

        guard case .available = availability else { return }

        recognizer.prepare()

        do {
            phase = try await resolve(transcript: transcript, knownHabits: knownHabits)
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
        case .parsing, .recognizing, .recognized, .done, .failed:
            break
        }
    }

    private func resolve(
        transcript: String,
        knownHabits: [Habit]
    ) async throws -> HabitCommandPhaseEnum {
        switch try await parser.parseCommand(in: transcript, from: knownHabits) {
        case .create(let draft):
            return .confirmingCreate(draft)
        case .delete(let habitID):
            guard let habit = knownHabits.first(where: { $0.id == habitID }) else {
                throw HabitCommandErrorEnum.habitNotFound
            }
            return .confirmingDelete(habit)
        case .listCompleted:
            phase = .recognizing
            return .recognized(
                try await recognizer.recognizeCompletions(in: transcript, from: knownHabits)
            )
        }
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
