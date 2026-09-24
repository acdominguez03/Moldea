//
//  GetTodayProgressUseCase.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import Foundation

public protocol GetTodayProgressUseCase: Sendable {
    func execute(on day: Date) -> Double
}

public struct DefaultGetTodayProgressUseCase: GetTodayProgressUseCase {
    private let store: any TodayProgressStore

    public init(store: any TodayProgressStore) {
        self.store = store
    }

    public func execute(on day: Date = .now) -> Double {
        store.fraction(on: day)
    }
}
