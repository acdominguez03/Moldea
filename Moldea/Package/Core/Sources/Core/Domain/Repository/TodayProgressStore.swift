//
//  TodayProgressStore.swift
//  Core
//
//  Created by Ismael Cordón Domínguez on 24/9/26.
//

import Foundation

public protocol TodayProgressStore: Sendable {
    func save(fraction: Double, on day: Date)

    func fraction(on day: Date) -> Double
}
