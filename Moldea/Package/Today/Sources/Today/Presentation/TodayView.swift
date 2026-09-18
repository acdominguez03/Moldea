//
//  TodayView.swift
//  Today
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Core

public struct TodayView: View {
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                
            }
            .navigationTitle(TodayTextsEnum.screenTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    TodayView()
}
