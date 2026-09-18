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
    public private(set) var flow: AppFlow

    public init(initialFlow: AppFlow = .tabView) {
        self.flow = initialFlow
    }

    func navigate(value: AppFlow) {
        flow = value
    }
}
