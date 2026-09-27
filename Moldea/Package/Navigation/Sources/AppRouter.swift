//
//  AppRouter.swift
//  Navigation
//
//  Created by Andrés on 18/09/2026.
//


import Foundation
import SwiftUI

@Observable
public class AppRouter {
    public private(set) var flow: AppFlowEnum

    public init(initialFlow: AppFlowEnum = .tabView) {
        self.flow = initialFlow
    }

    public func finishSplash() {
        withAnimation(.easeInOut(duration: 0.4)) {
            navigate(value: .tabView)
        }
    }

    func navigate(value: AppFlowEnum) {
        flow = value
    }
}
