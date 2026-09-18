//
//  StatisticsView.swift
//  Statistics
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Core

public struct StatisticsView: View {
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                
            }
            .navigationTitle(StatisticsTextsEnum.screenTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    StatisticsView()
}
