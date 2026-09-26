//
//  SwiftUIView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI
import Core

struct HabitSummaryView: View {
    let color: Color
    let icon: String
    let name: String
    let onHabitNameChanged: (String) -> Void
    
    private var nameBinding: Binding<String> {
        Binding(get: { name }, set: { onHabitNameChanged($0) })
      }
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(spacing: 16))

        layout {
            HabitIconBadge(color: color, icon: icon, style: .solid, size: .large)

            VStack {
                TextField(
                    text: nameBinding,
                    prompt: Text(HabitsTextsEnum.habitNamePlaceholder)
                ) {
                    Text(HabitsTextsEnum.habitNamePlaceholder)
                }
                .font(.title2)

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
