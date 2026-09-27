//
//  SpeechToTextView.swift
//  Core
//
//  Created by Andrés on 19/09/2026.
//

import SwiftUI

public struct SpeechToTextView: View {
    @Environment(\.coreDependencies) private var dependencies

    public init() {}

    public var body: some View {
        if let dependencies {
            SpeechToTextContentView(viewModel: dependencies.makeSpeechToTextViewModel())
        } else {
            MissingDependenciesView(CoreDependencies.self)
        }
    }
}

struct SpeechToTextContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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

    init(viewModel: SpeechToTextViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView { content }
            } else {
                content
            }
        }
        .navigationTitle(CoreTextsEnum.listening)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: isPresentingCommand) {
            if let commandViewModel = viewModel.commandViewModel {
                HabitCommandView(
                    transcript: viewModel.transcriptForAI,
                    viewModel: commandViewModel,
                    onFinish: {
                        viewModel.stop()
                        dismiss()
                    }
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    viewModel.stop()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .disabled(!viewModel.canClose)
            }
        }
        .task {
            await viewModel.start()
        }
        .onChange(of: viewModel.phase) {
            guard case .failed(let message) = viewModel.phase else { return }
            AccessibilityNotification.Announcement(String(localized: message)).post()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private var content: some View {
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
                Label {
                    Text(message)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
                .font(.footnote)
                .multilineTextAlignment(.center)
            case .idle, .transcribing:
                EmptyView()
            }

            WaveAnimation(isActive: viewModel.isTranscribing)

            Button(CoreTextsEnum.finish) {
                Task {
                    await viewModel.finishAndRecognize()
                }
            }
            .buttonStyle(.glassProminent)
            .buttonSizing(.flexible)
            .controlSize(.large)
            .disabled(!viewModel.canFinish)
            
            Text(CoreTextsEnum.speechToTextDescription)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
    }
}

#Preview(traits: .moldea) {
    SpeechToTextView()
}
