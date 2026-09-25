//
//  MoldeaShortcuts.swift
//  Moldea
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

import AppIntents

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
        AppShortcut(
            intent: CompleteHabitIntent(),
            phrases: [
                "Complete my habit \(\.$habit) in \(.applicationName)",
                "Log my habit \(\.$habit) in \(.applicationName)",
                "Check off my habit \(\.$habit) in \(.applicationName)",
                "Complete a habit in \(.applicationName)",
                "Mark a habit as done in \(.applicationName)"
            ],
            shortTitle: "Complete a habit",
            systemImageName: "checkmark.circle"
        )
    }
}
