//
//  TabRouter.swift
//  Navigation
//
//  Created by Andrés on 18/09/2026.
//


import Foundation

@Observable
public class TabRouter {
    public var selectedTab: MainTabEnum = .today
    
    public init() {}
    
    public func present(tab: MainTabEnum) {
        selectedTab = tab
    }
}
