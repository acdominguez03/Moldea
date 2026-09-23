//
//  MoldeaShortcuts.swift
//  Moldea
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

import AppIntents

/// Los App Shortcuts disponibles desde Siri, Spotlight y Atajos en cuanto se instala la app.
/// Solo puede haber un `AppShortcutsProvider` por app, y como máximo 10 atajos.
struct MoldeaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetTodayProgressIntent(),
            phrases: [
                "What is my habits progress in \(.applicationName)",
                "How are my habits going in \(.applicationName)",
                "Check my habits progress in \(.applicationName)",
                "Show my daily progress in \(.applicationName)"
            ],
            shortTitle: "Today's progress",
            systemImageName: "chart.pie"
        )
    }
}
