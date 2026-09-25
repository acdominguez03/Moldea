//
//  HabitCommandView.swift
//  Core
//
//  Created by Andrés on 22/09/2026.
//

import SwiftUI

struct HabitCommandView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: HabitCommandViewModel

    private let transcript: String
    private let onFinish: () -> Void

    @HabitsQuery private var knownHabits: [Habit]

    init(
        transcript: String,
        createHabitUseCase: any CreateHabitUseCase,
        deleteHabitUseCase: any DeleteHabitUseCase,
        completeHabitsUseCase: any CompleteHabitsUseCase,
        getTodayHabitsUseCase: any GetTodayHabitsUseCase,
        onFinish: @escaping () -> Void,
        parser: any HabitCommandParsing = FoundationModelsHabitCommandParser()
    ) {
        self.transcript = transcript
        self.onFinish = onFinish
        _viewModel = State(
            initialValue: HabitCommandViewModel(
                parser: parser,
                createHabitUseCase: createHabitUseCase,
                deleteHabitUseCase: deleteHabitUseCase,
                completeHabitsUseCase: completeHabitsUseCase,
                getTodayHabitsUseCase: getTodayHabitsUseCase
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let unavailableMessage = viewModel.unavailableMessage {
                    HabitCommandMessage(text: unavailableMessage)
                } else {
                    GlassEffectContainer(spacing: 16) {
                        VStack(spacing: 16) {
                            phaseContent
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(CoreTextsEnum.aiCommandTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.handle(transcript: transcript, knownHabits: knownHabits)
        }
        .task(id: viewModel.phase) {
            guard viewModel.shouldAutoDismiss else { return }

            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }

            onFinish()
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.phase {
        case .parsing:
            HabitCommandProgress(text: CoreTextsEnum.aiCommandParsing)
        case .confirmingCreate(let draft):
            HabitCommandConfirmation(
                title: CoreTextsEnum.aiCommandCreateTitle(draft.name),
                message: viewModel.errorMessage,
                isConfirming: viewModel.isLoading,
                onRepeat: { dismiss() },
                onConfirm: confirm
            ) {
                HabitCardView(draft: draft)
            }
        case .confirmingDelete(let habit):
            HabitCommandConfirmation(
                title: CoreTextsEnum.aiCommandDeleteTitle(habit.name),
                message: viewModel.errorMessage,
                isConfirming: viewModel.isLoading,
                onRepeat: { dismiss() },
                onConfirm: confirm
            ) {
                HabitCardView(habit: habit)
            }
        case .done(let outcome):
            HabitCommandOutcomeSummary(outcome: outcome)

            if case .completed = outcome {
                HabitCommandRepeatButton(onRepeat: { dismiss() })
            }
        case .failed:
            if let errorMessage = viewModel.errorMessage {
                HabitCommandMessage(text: errorMessage)
            }

            HabitCommandRepeatButton(onRepeat: { dismiss() })
        }
    }

    private func confirm() {
        Task {
            await viewModel.confirm()
            if case .done = viewModel.phase {
                onFinish()
            }
        }
    }
}

private struct HabitCommandProgress: View {
    let text: LocalizedStringResource

    var body: some View {
        ProgressView {
            Text(text)
        }
    }
}

private struct HabitCommandConfirmation<Card: View>: View {
    let title: LocalizedStringResource
    let message: LocalizedStringResource?
    let isConfirming: Bool
    let onRepeat: () -> Void
    let onConfirm: () -> Void
    @ViewBuilder let card: Card

    var body: some View {
        HabitCommandTitle(text: title)

        HabitCommandCard { card }

        if let message {
            HabitCommandMessage(text: message)
        }

        HStack(spacing: 12) {
            Button(action: onRepeat) {
                Text(CoreTextsEnum.aiCommandRepeat)
            }
            .buttonStyle(.glass)

            Button(action: onConfirm) {
                Text(CoreTextsEnum.aiCommandConfirm)
            }
            .buttonStyle(.glassProminent)
        }
        .buttonSizing(.flexible)
        .disabled(isConfirming)
    }
}

private struct HabitCommandOutcomeSummary: View {
    let outcome: HabitCommandOutcomeEnum

    var body: some View {
        switch outcome {
        case .created(let draft):
            HabitCommandTitle(text: CoreTextsEnum.aiCommandCreated(draft.name))
            HabitCommandCard { HabitCardView(draft: draft) }
        case .deleted(let habit):
            HabitCommandTitle(text: CoreTextsEnum.aiCommandDeleted(habit.name))
            HabitCommandCard { HabitCardView(habit: habit) }
        case .completed(let completed, let alreadyCompleted):
            ForEach(completed) { habit in
                HabitCommandTitle(text: CoreTextsEnum.aiCommandCompleted(habit.name))
                HabitCommandCard { HabitCardView(habit: habit) }
            }

            ForEach(alreadyCompleted) { habit in
                HabitCommandMessage(text: CoreTextsEnum.aiCommandAlreadyCompleted(habit.name))
            }
        }
    }
}

private struct HabitCommandRepeatButton: View {
    let onRepeat: () -> Void

    var body: some View {
        Button(action: onRepeat) {
            Text(CoreTextsEnum.aiCommandRepeat)
        }
        .buttonStyle(.glass)
        .buttonSizing(.flexible)
    }
}

private struct HabitCommandCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding()
            .glassEffect(in: .rect(cornerRadius: 20))
    }
}

private struct HabitCommandTitle: View {
    let text: LocalizedStringResource

    var body: some View {
        Text(text)
            .font(.headline)
            .multilineTextAlignment(.center)
    }
}

private struct HabitCommandMessage: View {
    let text: LocalizedStringResource

    var body: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}
