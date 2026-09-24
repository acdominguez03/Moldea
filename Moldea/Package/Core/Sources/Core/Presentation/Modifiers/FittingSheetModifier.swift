//
//  FittingSheetModifier.swift
//  Core
//
//  Created by Andrés on 24/09/2026.
//


import SwiftUI

private struct FittingSheetModifier: ViewModifier {
    let extraDetents: Set<PresentationDetent>

    @State private var measuredHeight: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { newHeight in
                measuredHeight = max(1, newHeight)
            }
            .presentationDetents(
                Set([.height(measuredHeight)]).union(extraDetents)
            )
    }
}

public extension View {
    func fittingSheetDetents(
        extraDetents: Set<PresentationDetent> = []
    ) -> some View {
        modifier(FittingSheetModifier(extraDetents: extraDetents))
    }
}
