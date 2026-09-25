//
//  HabitProgressCard.swift
//  Statistics
//
//  Created by Andrés on 24/09/2026.
//

import SwiftUI

struct HabitProgressCard: View {
    let color: Color
    let name: String
    let percentage: Int
    
    init(color: Color, name: String, percentage: Int) {
        self.color = color
        self.name = name
        self.percentage = percentage
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .frame(width: 10, height: 10)
                .foregroundStyle(color)
            
            Text(name)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
            
            ProgressView(value: Double(percentage), total: 100)
                .progressViewStyle(.linear)
                .tint(color)
                .frame(maxWidth: 100)
            
            Text(100, format: .percent)
                .hidden()
                .overlay(alignment: .trailing) {
                    Text(percentage, format: .percent)
                }
                .font(.body)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }
}

#Preview {
    HabitProgressCard(color: .red, name: "Correr", percentage: 75)
}
