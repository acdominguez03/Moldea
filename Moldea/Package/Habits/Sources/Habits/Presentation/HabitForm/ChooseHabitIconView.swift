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
    @State private var lineWidth: CGFloat?

    private struct ScrollRequest: Equatable {
        let familyKey: String
        let id = UUID()
    }

    let selectedIcon: String
    let tint: Color
    let onIconSelected: (String) -> Void

    @ScaledMetric(relativeTo: .title2) private var minimumItemSize: CGFloat = 44
    @ScaledMetric(relativeTo: .title2) private var maximumItemSize: CGFloat = 52

    private let itemSpacing: CGFloat = 10

    private var columnCount: Int {
        guard let lineWidth, lineWidth > 0 else { return 6 }
        return max(1, Int((lineWidth + itemSpacing) / (minimumItemSize + itemSpacing)))
    }

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
                        let lines = family.symbols.chunked(into: columnCount)
                        ForEach(lines.indices, id: \.self) { index in
                            let isFirst = index == 0
                            let isLast = index == lines.count - 1
                            iconLine(lines[index])
                                .padding(.top, isFirst ? 4 : 0)
                                .padding(.bottom, isLast ? 4 : 0)
                                .listRowInsets(.top, isFirst ? nil : itemSpacing / 2)
                                .listRowInsets(.bottom, isLast ? nil : itemSpacing / 2)
                                .listRowSeparator(.hidden)
                        }
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

    private func iconLine(_ symbols: [String]) -> some View {
        HStack(spacing: itemSpacing) {
            ForEach(symbols, id: \.self) { symbol in
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
                .frame(maxWidth: maximumItemSize)
                .frame(maxWidth: .infinity)
            }
            ForEach(symbols.count..<columnCount, id: \.self) { _ in
                Color.clear.frame(maxWidth: .infinity)
            }
        }
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.width
        } action: { width in
            lineWidth = width
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { start in
            Array(self[start..<Swift.min(start + size, count)])
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
