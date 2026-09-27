//
//  SplashView.swift
//  Moldea
//

import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsIcon = false
    @State private var showsName = false

    private let iconSize: CGFloat = 120

    var body: some View {
        VStack(spacing: 20) {
            Image(.splashIcon)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .clipShape(.rect(cornerRadius: iconSize * 0.2237, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                .scaleEffect(showsIcon || reduceMotion ? 1 : 0.6)
                .opacity(showsIcon ? 1 : 0)
                .accessibilityHidden(true)

            Text(verbatim: "Moldea")
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
                .offset(y: showsName || reduceMotion ? 0 : 12)
                .opacity(showsName ? 1 : 0)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            withAnimation(reduceMotion ? .easeIn(duration: 0.3) : .spring(duration: 0.6, bounce: 0.4)) {
                showsIcon = true
            }
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(reduceMotion ? .easeIn(duration: 0.3) : .spring(duration: 0.5, bounce: 0.2)) {
                showsName = true
            }
            try? await Task.sleep(for: .milliseconds(1100))
            onFinished()
        }
    }
}

#Preview {
    SplashView {}
}
