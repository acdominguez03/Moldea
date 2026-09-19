//
//  WaveAnimation.swift
//  Core
//
//  Created by Andrés on 19/09/2026.
//

import SwiftUI

struct WaveAnimation: View {
    private static let barCount = 11

    let isActive: Bool

    var body: some View {
        HStack {
            ForEach(0 ..< Self.barCount, id: \.self) { _ in
                WaveItemAnimation(isActive: isActive)
            }
        }
    }
}

#Preview {
    WaveAnimation(isActive: true)
}

#Preview("Inactive") {
    WaveAnimation(isActive: false)
}
