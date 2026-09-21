//
//  HabitsView.swift
//  Habits
//
//  Created by Andrés on 18/09/2026.
//

import SwiftUI
import Core

public struct HabitsView: View {
    @State private var isSheetPresented: Bool = false
    
    private let createHabitUseCase: any CreateHabitUseCase
    
    public init(habitRepository: any HabitRepository) {
        self.createHabitUseCase = DefaultCreateHabitUseCase(repository: habitRepository)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                
            }
            .navigationTitle(HabitsTextsEnum.screenTitle)
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isSheetPresented = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isSheetPresented) {
                CreateHabitView(
                    createHabitViewModel: CreateHabitViewModel(createHabitUseCase: createHabitUseCase),
                    iconCatalog: BundleHabitIconCatalog()
                )
            }
        }
    }
}

#Preview {
    HabitsView(
        habitRepository: SwiftDataHabitRepository(
            modelContainer: try! MoldeaSchema.makeModelContainer(inMemory: true)
        )
    )
}
