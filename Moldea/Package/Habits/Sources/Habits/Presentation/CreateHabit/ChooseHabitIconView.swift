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

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

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

        VStack(spacing: 0) {
            if searchText.isEmpty {
                familyChips(viewModel.families)
            }

            if sections.isEmpty, !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                iconSections(sections)
            }
        }
        .navigationTitle(HabitsTextsEnum.chooseIconTitle)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: HabitsTextsEnum.iconSearchPrompt)
        .task { await viewModel.load() }
    }

    private func familyChips(_ families: [HabitIconFamily]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(families) { family in
                    let isHighlighted = family.key == (selectedFamilyKey ?? families.first?.key)

                    Button {
                        selectedFamilyKey = family.key
                        scrollRequest = ScrollRequest(familyKey: family.key)
                    } label: {
                        Text(family.name)
                            .font(.subheadline)
                            .foregroundStyle(isHighlighted ? Color.white : Color.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isHighlighted ? tint : Color.secondary.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isHighlighted ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .padding(.vertical, 8)
    }

    private func iconSections(_ sections: [HabitIconFamily]) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(sections) { family in
                        Section {
                            LazyVGrid(columns: columns, spacing: 0) {
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
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 16)
                        } header: {
                            Text(family.name)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.bar)
                                .id(family.key)
                        }
                    }
                }
            }
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
