//
//  TodayCompletionCheck.swift
//  Today
//
//  Created by Andrés on 23/09/2026.
//

import SwiftUI
import Core

struct TodayCompletionCheck: View {
    private static let size: CGFloat = 34

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
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .strokeBorder(.tertiary, lineWidth: 1.5)

                    if total > 1 {
                        Text(verbatim: "\(completed.formatted())/\(total.formatted())")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(color)
                            .monospacedDigit()
                    }
                }
            }
            .frame(width: Self.size, height: Self.size)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(TodayTextsEnum.completionLabel))
        .accessibilityValue(Text(TodayTextsEnum.progressToday(completed, total)))
        .accessibilityHint(Text(TodayTextsEnum.completionHint))
    }
}

#Preview {
    HStack(spacing: 24) {
        TodayCompletionCheck(completed: 0, total: 1, color: .blue) {}
        TodayCompletionCheck(completed: 1, total: 1, color: .blue) {}
        TodayCompletionCheck(completed: 0, total: 4, color: .green) {}
        TodayCompletionCheck(completed: 2, total: 4, color: .green) {}
        TodayCompletionCheck(completed: 4, total: 4, color: .green) {}
    }
    .padding()
}
