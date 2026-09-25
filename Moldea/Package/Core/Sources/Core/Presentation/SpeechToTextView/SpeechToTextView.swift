//
//  SpeechToTextView.swift
//  Core
//
//  Created by Andrés on 19/09/2026.
//

import SwiftUI

public struct SpeechToTextView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: SpeechToTextViewModel
    
    private var isPresentingCommand: Binding<Bool> {
        Binding(
            get: { viewModel.isPresentingCommand },
            set: { isPresented in
                guard !isPresented else { return }
                viewModel.dismissCommand()
            }
        )
    }

    public init(
        habitRepository: any HabitRepository,
        todayHabitsRepository: any TodayHabitsRepository,
        userDefaultsRepository: any UserDefaultsRepository
    ) {
        _viewModel = State(
            initialValue: SpeechToTextViewModel(
                habitRepository: habitRepository,
                todayHabitsRepository: todayHabitsRepository,
                notificationScheduler: UNUserNotificationCenterHabitNotificationScheduler(
                    userDefaultsRepository: userDefaultsRepository
                )
            )
        )
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Group {
                if viewModel.hasTranscript {
                    Text(viewModel.styledTranscript)
                } else {
                    Text(CoreTextsEnum.speechToTextPlaceholder)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.body)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            
            switch viewModel.phase {
            case .preparing:
                if let progress = viewModel.downloadProgress {
                    ProgressView(progress)
                        .font(.footnote)
                } else {
                    ProgressView {
                        Text(CoreTextsEnum.speechToTextPreparing)
                    }
                    .font(.footnote)
                }
            case .failed(let message):
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            case .idle, .transcribing:
                EmptyView()
            }
            
            WaveAnimation(isActive: viewModel.isTranscribing)
                .accessibilityHidden(true)
            
            Button {
                Task { await viewModel.finishAndRecognize() }
            } label: {
                Text(CoreTextsEnum.finish)
            }
            .buttonStyle(.glass)
            .buttonSizing(.flexible)
            .disabled(!viewModel.canFinish)
            
            Text(CoreTextsEnum.speechToTextDescription)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
        .navigationTitle(CoreTextsEnum.listening)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: isPresentingCommand) {
            HabitCommandView(
                transcript: viewModel.transcriptForAI,
                createHabitUseCase: viewModel.createHabitUseCase,
                deleteHabitUseCase: viewModel.deleteHabitUseCase,
                completeHabitsUseCase: viewModel.completeHabitsUseCase,
                getTodayHabitsUseCase: viewModel.getTodayHabitsUseCase,
                onFinish: {
                    viewModel.stop()
                    dismiss()
                },
                parser: viewModel.parser
            )
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    viewModel.stop()
                    dismiss()
                } label: {
                    Text(CoreTextsEnum.close)
                }
                .disabled(!viewModel.canClose)
            }
        }
        .task {
            await viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}
