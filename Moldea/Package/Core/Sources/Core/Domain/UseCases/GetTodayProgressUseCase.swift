//
//  GetTodayProgressUseCase.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 23/9/26.
//

/// Progreso de hoy como fracción de 0 a 1 (0.9 = 90 %).
public protocol GetTodayProgressUseCase: Sendable {
    func execute() async throws -> Double
}

/// Provisional: devuelve un valor aleatorio hasta que exista la lógica real.
public struct DefaultGetTodayProgressUseCase: GetTodayProgressUseCase {
    public init() {}

    public func execute() async throws -> Double {
        Double.random(in: 0...1)
    }
}
