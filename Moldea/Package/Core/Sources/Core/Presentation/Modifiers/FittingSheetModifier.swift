//
//  FittingSheetModifier.swift
//  Core
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI

private struct FittingSheetModifier: ViewModifier {
    let extraDetents: Set<PresentationDetent>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var measuredHeight: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { newHeight in
                measuredHeight = max(1, newHeight)
            }
            .presentationDetents(detents)
    }

    private var detents: Set<PresentationDetent> {
        var detents = Set([PresentationDetent.height(measuredHeight)]).union(extraDetents)
        if dynamicTypeSize.isAccessibilitySize {
            detents.insert(.large)
        }
        return detents
    }
}

public extension View {
    func fittingSheetDetents(
        extraDetents: Set<PresentationDetent> = []
    ) -> some View {
        modifier(FittingSheetModifier(extraDetents: extraDetents))
    }
}
