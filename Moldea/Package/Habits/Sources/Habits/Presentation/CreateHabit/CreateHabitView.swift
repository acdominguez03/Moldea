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
    @State private var createHabitViewModel: CreateHabitViewModel
    @State private var isShowingIconChooser = false

    private let iconCatalog: any HabitIconCatalog

    init(createHabitViewModel: CreateHabitViewModel, iconCatalog: any HabitIconCatalog) {
        self.createHabitViewModel = createHabitViewModel
        self.iconCatalog = iconCatalog
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(HabitsTextsEnum.iconTitle)
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HabitIconPicker(
                        selectedIcon: createHabitViewModel.selectedIcon,
                        tint: createHabitViewModel.selectedColor ?? .accentColor,
                        onIconSelected: { createHabitViewModel.selectIcon($0) },
                        onMoreTapped: { isShowingIconChooser = true }
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(HabitsTextsEnum.colorTitle)
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HabitColorPicker(
                        selectedColor: createHabitViewModel.selectedColor,
                        onColorSelected: { createHabitViewModel.selectColor($0) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle(HabitsTextsEnum.newHabit)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isShowingIconChooser) {
                ChooseHabitIconView(
                    catalog: iconCatalog,
                    selectedIcon: createHabitViewModel.selectedIcon,
                    tint: createHabitViewModel.selectedColor ?? .accentColor,
                    onIconSelected: { createHabitViewModel.selectIcon($0) }
                )
            }
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
    CreateHabitView(
        createHabitViewModel: CreateHabitViewModel(),
        iconCatalog: BundleHabitIconCatalog()
    )
}
