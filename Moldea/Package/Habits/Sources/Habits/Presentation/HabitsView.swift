//
//  HabitsView.swift
//  Habits
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Core

public struct HabitsView: View {
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                
            }
            .navigationTitle(HabitsTextsEnum.screenTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    HabitsView()
}
