//
//  ReminderPlanSource.swift
//  Core
//

import Foundation

public protocol ReminderPlanSource: Sendable {
    /// Todos los hábitos, no solo los de hoy, con si ya están completados en `day`.
    func fetchCandidates(on day: Date) async throws -> [ReminderCandidate]
}
