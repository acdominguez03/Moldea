//
//  FittingScrollSheetModifier.swift
//  Core
//

import SwiftUI

private struct FittingScrollSheetModifier: ViewModifier {
    let extraDetents: Set<PresentationDetent>

    @State private var measuredHeight: CGFloat?

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentSize.height
                    + geometry.contentInsets.top
                    + geometry.contentInsets.bottom
            } action: { _, newHeight in
                measuredHeight = newHeight
            }
            .presentationDetents(detents)
    }

    private var detents: Set<PresentationDetent> {
        let fitting: PresentationDetent = measuredHeight.map { .height($0) } ?? .medium
        return Set([fitting]).union(extraDetents)
    }
}

public extension View {
    func fittingScrollSheetDetents(
        extraDetents: Set<PresentationDetent> = []
    ) -> some View {
        modifier(FittingScrollSheetModifier(extraDetents: extraDetents))
    }
}
