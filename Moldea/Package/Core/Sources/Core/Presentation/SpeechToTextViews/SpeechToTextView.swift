//
//  SpeechToTextView.swift
//  Core
//
//  Created by Andrés on 19/09/2026.
//

import SwiftUI

public struct SpeechToTextView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = "He bebido dos litros de agua, he leído un rato"
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

            WaveAnimation()
                .accessibilityHidden(true)

            Button {

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
                    dismiss()
                } label: {
                    Text(CoreTextsEnum.close)
                }
            }
        }
    }
}

#Preview {
    // Se presenta como hoja para poder comprobar el ajuste de altura al contenido.
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                SpeechToTextView()
            }
            .presentationDragIndicator(.visible)
        }
}
