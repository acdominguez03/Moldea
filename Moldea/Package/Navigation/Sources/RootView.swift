//
//  RootView.swift
//  Navigation
//
//  Created by Andrés on 18/09/2026.
//



import SwiftUI

public struct RootView<Content: View>: View {
    private var router: AppRouter
    private var content: (AppFlowEnum) -> Content
    
    public init(router: AppRouter, @ViewBuilder content: @escaping (AppFlowEnum) -> Content) {
        self.router = router
        self.content = content
    }
    
    public var body: some View {
        content(router.flow)
            .environment(router)
    }
}
