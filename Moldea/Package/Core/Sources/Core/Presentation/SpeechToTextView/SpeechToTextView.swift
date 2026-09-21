//
//  SpeechToTextView.swift
//  Core
//
//  Created by Andrés on 19/09/2026.
//

import SwiftUI

public struct SpeechToTextView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var model = LiveTranscriptionModel()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            transcript
            
            status
            
            WaveAnimation(isActive: model.isTranscribing)
                .accessibilityHidden(true)
            
            Button {
                finish()
            } label: {
                Text(CoreTextsEnum.finish)
            }
            .buttonStyle(.glass)
            .buttonSizing(.flexible)
            
            Text(CoreTextsEnum.speechToTextDescription)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.body)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .navigationTitle(CoreTextsEnum.listening)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    finish()
                } label: {
                    Text(CoreTextsEnum.close)
                }
                .disabled(model.isPreparing)
            }
        }
        .task {
            model.startTranscribing()
        }
        .onDisappear {
            model.stopTranscribing()
        }
    }
    
    private var transcript: some View {
        
        Group {
            if model.hasTranscript {
                Text(model.finalizedText + dimmedVolatileText)
            } else {
                Text(CoreTextsEnum.speechToTextPlaceholder)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.body)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var dimmedVolatileText: AttributedString {
        var text = model.volatileText
        text.foregroundColor = .secondary
        return text
    }
    
    @ViewBuilder
    private var status: some View {
        switch model.phase {
        case .preparing:
            if let progress = model.downloadProgress {
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
    }
    
    private func finish() {
        model.stopTranscribing()
        dismiss()
    }
}
