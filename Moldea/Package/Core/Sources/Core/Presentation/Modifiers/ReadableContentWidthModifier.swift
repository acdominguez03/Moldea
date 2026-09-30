//
//  ReadableContentWidthModifier.swift
//  Core
//
//  Created by Andrés on 30/09/2026.
//

import SwiftUI

private struct ReadableContentWidthModifier: ViewModifier {
    let maxWidth: CGFloat

    @State private var containerWidth: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.horizontal, horizontalPadding)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { newWidth in
                containerWidth = newWidth
            }
    }

    private var horizontalPadding: CGFloat {
        max((containerWidth - maxWidth) / 2, 0)
    }
}

public extension View {
    func readableContentWidth(_ maxWidth: CGFloat = 700) -> some View {
        modifier(ReadableContentWidthModifier(maxWidth: maxWidth))
    }
}
