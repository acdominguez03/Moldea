//
//  GetTodayProgressIntent.swift
//  Moldea
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

import AppIntents
import Core

/// Le dice al usuario, en voz alta, cuánto lleva completado hoy.
struct GetTodayProgressIntent: AppIntent {
    static let title: LocalizedStringResource = "Get today's progress"
    static let description = IntentDescription("Tells you the percentage of today's habits you have completed.")

    /// Es una consulta: no hace falta abrir la app.
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        // TODO: inyectar con @Dependency cuando el caso de uso lea datos reales.
        let progress = try await DefaultGetTodayProgressUseCase().execute()
        let percentage = progress.formatted(.percent.precision(.fractionLength(0)))

        return .result(
            value: progress,
            dialog: "Today you have completed \(percentage) of your habits."
        )
    }
}
