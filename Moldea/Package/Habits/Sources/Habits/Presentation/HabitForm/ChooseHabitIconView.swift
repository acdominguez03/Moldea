//
//  ChooseHabitIconView.swift
//  Habits
//
//  Created by Ismael Cordón Domínguez on 19/9/26.
//

import SwiftUI

struct ChooseHabitIconView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ChooseHabitIconViewModel
    @State private var searchText = ""
    @State private var selectedFamilyKey: String?
    @State private var scrollRequest: ScrollRequest?

    private struct ScrollRequest: Equatable {
        let familyKey: String
        let id = UUID()
    }

    let selectedIcon: String
    let tint: Color
    let onIconSelected: (String) -> Void

    private let columns = [GridItem(.adaptive(minimum: 44, maximum: 52), spacing: 10)]

    init(
        catalog: any HabitIconCatalog,
        selectedIcon: String,
        tint: Color,
        onIconSelected: @escaping (String) -> Void
    ) {
        _viewModel = State(initialValue: ChooseHabitIconViewModel(catalog: catalog))
        self.selectedIcon = selectedIcon
        self.tint = tint
        self.onIconSelected = onIconSelected
    }

    var body: some View {
        let sections = viewModel.sections(matching: searchText)

        Group {
            if sections.isEmpty, !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                iconSections(sections)
            }
        }
        .navigationTitle(HabitsTextsEnum.chooseIconTitle)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: HabitsTextsEnum.iconSearchPrompt)
        .toolbar {
            if searchText.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    familyMenu(viewModel.families)
                }
            }
        }
        .task { await viewModel.load() }
    }

    private func familyMenu(_ families: [HabitIconFamily]) -> some View {
        let selection = Binding<String?>(
            get: { selectedFamilyKey ?? families.first?.key },
            set: { key in
                guard let key else { return }
                selectedFamilyKey = key
                scrollRequest = ScrollRequest(familyKey: key)
            }
        )

        return Menu {
            Picker(HabitsTextsEnum.iconCategories, selection: selection) {
                ForEach(families) { family in
                    Text(family.name).tag(Optional(family.key))
                }
            }
        } label: {
            Label(HabitsTextsEnum.iconCategories, systemImage: "square.grid.2x2")
        }
    }

    private func iconSections(_ sections: [HabitIconFamily]) -> some View {
        ScrollViewReader { proxy in
            List {
                ForEach(sections) { family in
                    Section {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(family.symbols, id: \.self) { symbol in
                                HabitIconPickerItem(
                                    systemName: symbol,
                                    name: symbol.replacingOccurrences(of: ".", with: " "),
                                    isSelected: symbol == selectedIcon,
                                    tint: tint,
                                    action: {
                                        onIconSelected(symbol)
                                        dismiss()
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text(family.name)
                    }
                    .id(family.key)
                }
            }
            .listStyle(.insetGrouped)
            .onChange(of: scrollRequest) { _, request in
                guard let request else { return }
                withAnimation { proxy.scrollTo(request.familyKey, anchor: .top) }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChooseHabitIconView(
            catalog: BundleHabitIconCatalog(),
            selectedIcon: "drop",
            tint: .blue,
            onIconSelected: { _ in }
        )
    }
}
