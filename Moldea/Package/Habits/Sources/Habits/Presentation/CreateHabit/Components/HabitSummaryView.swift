//
//  SwiftUIView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI

struct HabitSummaryView: View {
    let color: Color
    let icon: String
    let name: String
    let onHabitNameChanged: (String) -> Void
    
    private var nameBinding: Binding<String> {
        Binding(get: { name }, set: { onHabitNameChanged($0) })
      }
    
    var body: some View {
        HStack(spacing: 12) {
            HabitIconBadge(color: color, icon: icon)

            VStack {
                TextField(
                    text: nameBinding,
                    prompt: Text(HabitsTextsEnum.habitNamePlaceholder)
                ) {
                    Text(HabitsTextsEnum.habitNamePlaceholder)
                }
                
                Divider()
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    @Previewable @State var name = ""
    
    HabitSummaryView(
        color: .blue,
        icon: "drop",
        name: name,
        onHabitNameChanged: { name = $0 }
    )
    .padding()
}
