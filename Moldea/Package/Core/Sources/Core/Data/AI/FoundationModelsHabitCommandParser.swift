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
        from knownHabits: [Habit],
        today todayHabits: [TodayHabit]
    ) async throws -> HabitCommandEnum {
        guard case .available = availability else {
            throw LanguageModelErrorEnum.sessionUnavailable
        }

        let phrase = Self.singleLine(transcript)
        guard !phrase.isEmpty else {
            throw HabitCommandErrorEnum.notUnderstood
        }

        switch try await intent(for: phrase) {
        case .complete:
            return try await completion(for: phrase, in: todayHabits)
        case .create:
            return .create(try await draft(for: phrase))
        case .delete:
            return .delete(habitID: try await habitID(for: phrase, in: knownHabits))
        }
    }

    // MARK: - Etapas

    private func intent(for phrase: String) async throws -> GenerableCommandIntentEnum {
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

        let session = makeSession(instructions: HabitCommandInstructions.habitToDeleteV2())

        let (activity, name): (String, String) = try await mappingErrors {
            let response = try await session.respond(
                schema: schema,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                "Hábitos del usuario: \(names.joined(separator: "; "))"

                "Frase del usuario: \(phrase)"

                "¿Qué hábito de la lista es la actividad que quiere borrar? Si no es ninguno de la lista, elige \(HabitNameSchema.noneOption)."
            }

            return (
                try response.content.value(String.self, forProperty: HabitNameSchema.activityPropertyKey),
                try response.content.value(String.self, forProperty: HabitNameSchema.habitPropertyKey)
            )
        }

        let habitID = try GenerableHabitMapper.habitID(forName: name, in: knownHabits)

        let target = Self.singleLine(activity)
        guard try await isSameActivity(target.isEmpty ? phrase : target, as: name) else {
            throw HabitCommandErrorEnum.habitNotFound
        }

        return habitID
    }

    private func isSameActivity(_ activity: String, as habitName: String) async throws -> Bool {
        let session = makeSession(instructions: HabitCommandInstructions.sameActivityV1())

        return try await mappingErrors {
            let response = try await session.respond(
                generating: GenerableActivityMatch.self,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                "Actividad del usuario: \(activity)"

                "Hábito: \(Self.singleLine(habitName))"

                "¿Son la misma actividad?"
            }

            return response.content.isSameActivity
        }
    }

    private func completion(
        for phrase: String,
        in todayHabits: [TodayHabit]
    ) async throws -> HabitCommandEnum {
        let habits = todayHabits.map(\.habit)
        let names = HabitNameSchema.uniqueNames(of: habits)
        guard !names.isEmpty else {
            return .complete(habitIDs: [])
        }

        let schema: GenerationSchema
        do {
            schema = try HabitNameSchema.makeCompletionSchema(for: habits)
        } catch {
            throw HabitCommandErrorEnum.schemaFailed
        }

        let session = makeSession(instructions: HabitCommandInstructions.habitsToCompleteV2())

        let done: [(activity: String, habit: String)] = try await mappingErrors {
            let response = try await session.respond(
                schema: schema,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                "Hábitos de hoy del usuario: \(names.map(Self.singleLine).joined(separator: "; "))"

                "Frase del usuario: \(phrase)"

                "¿Qué hábitos de la lista son actividades que dice haber hecho?"
            }

            return try response.content
                .value([GeneratedContent].self, forProperty: HabitNameSchema.donePropertyKey)
                .map { entry in
                    (
                        activity: try entry.value(String.self, forProperty: HabitNameSchema.activityPropertyKey),
                        habit: try entry.value(String.self, forProperty: HabitNameSchema.habitPropertyKey)
                    )
                }
        }

        var seen = Set<Habit.ID>()
        var habitIDs: [Habit.ID] = []
        for entry in done {
            guard let habitID = try? GenerableHabitMapper.habitID(forName: entry.habit, in: habits),
                  !seen.contains(habitID) else {
                continue
            }

            let activity = Self.singleLine(entry.activity)
            guard try await isSameActivity(activity.isEmpty ? phrase : activity, as: entry.habit) else {
                continue
            }

            seen.insert(habitID)
            habitIDs.append(habitID)
        }

        return .complete(habitIDs: habitIDs)
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
