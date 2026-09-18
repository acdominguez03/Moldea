//
//  SettingsView.swift
//  Settings
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Core

public struct SettingsView: View {
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                
            }
            .navigationTitle(SettingsTextsEnum.screenTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}
