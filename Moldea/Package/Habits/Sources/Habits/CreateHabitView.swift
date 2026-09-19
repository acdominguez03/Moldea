//
//  CreateHabitView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI
import Core

struct CreateHabitView: View {
    @Environment(\.dismiss) private var dismiss
    
    init() {}
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(HabitsTextsEnum.newHabit)
            }
            .navigationTitle(HabitsTextsEnum.newHabit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .confirmationAction,
                    content: {
                        Button {
                            dismiss()
                        } label: {
                            Text(CoreTextsEnum.save)
                        }
                    }
                )
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button {
                            dismiss()
                        } label: {
                            Text(CoreTextsEnum.cancel)
                        }
                    }
                )
            }
        }
    }
}

#Preview {
    CreateHabitView()
}
