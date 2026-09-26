//
//  TodayCompletionCheck.swift
//  Today
//
//  Created by Andrés on 23/09/2026.
//

import SwiftUI
import Core

struct TodayCompletionCheck: View {
    private static let minimumTouchTarget: CGFloat = 44

    @Environment(\.self) private var environment
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 34

    let name: String
    let completed: Int
    let total: Int
    let color: Color
    let action: () -> Void

    private var isCompleted: Bool { completed >= total }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isCompleted {
                    Circle()
                        .fill(color)

                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(ContrastingColor.foreground(on: color, in: environment))
                } else {
                    Circle()
                        .strokeBorder(.secondary, lineWidth: 1.5)

                    if total > 1 {
                        Text(verbatim: "\(completed.formatted())/\(total.formatted())")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .frame(width: size, height: size)
            .frame(
                width: max(size, Self.minimumTouchTarget),
                height: max(size, Self.minimumTouchTarget)
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(TodayTextsEnum.completionLabel(name)))
        .accessibilityValue(
            Text(isCompleted ? CoreTextsEnum.accessibilityCompleted : TodayTextsEnum.progressToday(completed, total))
        )
        .accessibilityHint(Text(TodayTextsEnum.completionHint))
        .accessibilityAddTraits(isCompleted ? .isSelected : [])
    }
}

#Preview {
    HStack(spacing: 24) {
        TodayCompletionCheck(name: "Leer", completed: 0, total: 1, color: .blue) {}
        TodayCompletionCheck(name: "Leer", completed: 1, total: 1, color: .blue) {}
        TodayCompletionCheck(name: "Correr", completed: 0, total: 4, color: .green) {}
        TodayCompletionCheck(name: "Correr", completed: 2, total: 4, color: .green) {}
        TodayCompletionCheck(name: "Correr", completed: 4, total: 4, color: .green) {}
    }
    .padding()
}
