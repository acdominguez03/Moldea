//
//  FoundationModelsHabitCommandParser.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

import Foundation
import FoundationModels

@MainActor
final class FoundationModelsHabitCommandParser: HabitCommandParsing {
    private let model: SystemLanguageModel
    private var preparedSession: LanguageModelSession?

    init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    var availability: LanguageModelAvailabilityEnum {
        if case .unavailable(let reason) = model.availability {
            return .unavailable(FoundationModelsErrorMapper.unavailableReason(for: reason))
        }

        guard model.supportsLocale(.current) else {
            return .unavailable(.localeNotSupported)
        }

        return .available
    }

    func prepare() {
        guard case .available = availability else { return }

        let session = makeSession(instructions: HabitCommandInstructions.intentV1())
        session.prewarm()
        preparedSession = session
    }

    func parseCommand(
        in transcript: String,
        from knownHabits: [Habit]
    ) async throws -> HabitCommandEnum {
        guard case .available = availability else {
            throw LanguageModelErrorEnum.sessionUnavailable
        }

        let phrase = Self.singleLine(transcript)
        guard !phrase.isEmpty else {
            throw HabitCommandErrorEnum.notUnderstood
        }

        switch try await intent(for: phrase) {
        case .listCompleted:
            return .listCompleted
        case .create:
            return .create(try await draft(for: phrase))
        case .delete:
            return .delete(habitID: try await habitID(for: phrase, in: knownHabits))
        }
    }

    // MARK: - Etapas

    private func intent(for phrase: String) async throws -> GenerableCommandIntent {
        let session = consumePreparedSession(
            instructions: HabitCommandInstructions.intentV1()
        )

        return try await mappingErrors {
            let response = try await session.respond(
                generating: GenerableCommandDecision.self,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                "Frase del usuario: \(phrase)"

                "¿Qué comando pide?"
            }

            return response.content.command
        }
    }

    private func draft(for phrase: String) async throws -> NewHabitDraft {
        let session = makeSession(instructions: HabitCommandInstructions.newHabitV1())

        let generated: GenerableHabitDraft = try await mappingErrors {
            let response = try await session.respond(
                generating: GenerableHabitDraft.self,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                "Frase del usuario: \(phrase)"

                "Extrae los datos del hábito que quiere crear."
            }

            return response.content
        }

        return try GenerableHabitMapper.draft(from: generated)
    }

    private func habitID(for phrase: String, in knownHabits: [Habit]) async throws -> Habit.ID {
        let names = HabitNameSchema.uniqueNames(of: knownHabits)
        guard !names.isEmpty else {
            throw HabitCommandErrorEnum.habitNotFound
        }

        let schema: GenerationSchema
        do {
            schema = try HabitNameSchema.makeSchema(for: knownHabits)
        } catch {
            throw HabitCommandErrorEnum.schemaFailed
        }

        let session = makeSession(instructions: HabitCommandInstructions.habitToDeleteV1())

        let name: String = try await mappingErrors {
            let response = try await session.respond(
                schema: schema,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                "Hábitos del usuario: \(names.joined(separator: "; "))"

                "Frase del usuario: \(phrase)"

                "¿A qué hábito de la lista se refiere?"
            }

            return try response.content.value(
                String.self,
                forProperty: HabitNameSchema.habitPropertyKey
            )
        }

        return try GenerableHabitMapper.habitID(forName: name, in: knownHabits)
    }

    // MARK: - Sesión

    private func makeSession(instructions: String) -> LanguageModelSession {
        LanguageModelSession(model: model, instructions: instructions)
    }

    private func consumePreparedSession(instructions: String) -> LanguageModelSession {
        defer {
            preparedSession = nil
        }
        return preparedSession ?? makeSession(instructions: instructions)
    }

    private func mappingErrors<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as CancellationError {
            throw error
        } catch let error as HabitCommandErrorEnum {
            throw error
        } catch {
            print("Foundation Models command request failed: \(error)")
            throw FoundationModelsErrorMapper.languageModelError(for: error)
        }
    }

    private static func singleLine(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
