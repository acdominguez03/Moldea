//
//  WaveItemAnimation.swift
//  Core
//
//  Created by Andrés on 19/09/2026.
//

import SwiftUI

struct WaveItemAnimation: View {
    private static let heightRange: ClosedRange<CGFloat> = 20 ... 60
    private static let restingHeight: CGFloat = 40
    private static let tickInterval: Duration = .milliseconds(200)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isActive: Bool

    @State private var height: CGFloat = WaveItemAnimation.restingHeight

    private var isAnimating: Bool { isActive && !reduceMotion }

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .frame(width: 20, height: height)
            .frame(height: Self.heightRange.upperBound, alignment: .bottom)
            .foregroundStyle(backgroundColor)
            .animation(
                reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.6),
                value: height
            )
            .task(id: isAnimating) {
                guard isAnimating else {
                    height = Self.restingHeight
                    return
                }

                while !Task.isCancelled {
                    do {
                        try await Task.sleep(for: Self.tickInterval)
                    } catch {
                        return
                    }
                    height = CGFloat.random(in: Self.heightRange)
                }
            }
    }

    private var backgroundColor: Color {
        return switch height {
        case ..<40:
            Color.gray
        case 40 ..< 50:
            Color.gray.opacity(0.6)
        default:
            Color.gray.opacity(0.4)
        }
    }
}

#Preview {
    WaveItemAnimation(isActive: true)
}

#Preview("Inactive") {
    WaveItemAnimation(isActive: false)
}
