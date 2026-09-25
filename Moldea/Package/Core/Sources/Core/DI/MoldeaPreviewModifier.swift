//
//  MoldeaPreviewModifier.swift
//  Core
//
//  Created by Andrés on 25/09/2026.
//

import SwiftData
import SwiftUI

struct MoldeaPreviewModifier: PreviewModifier {
    static func makeSharedContext() async throws -> CoreDependencies {
        let dependencies = CoreDependencies.preview
        let context = dependencies.modelContainer.mainContext
        if try context.fetchCount(FetchDescriptor<HabitEntity>()) == 0 {
            try SampleDataSeeder.seed(in: context)
        }
        return dependencies
    }

    func body(content: Content, context: CoreDependencies) -> some View {
        content
            .modelContainer(context.modelContainer)
            .environment(\.coreDependencies, context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    public static var moldea: Self { .modifier(MoldeaPreviewModifier()) }
}
