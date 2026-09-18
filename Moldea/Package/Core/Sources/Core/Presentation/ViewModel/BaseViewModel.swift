//
//  LoadableViewModel.swift
//  Core
//
//  Created by Andrés on 18/09/2026.
//

import Foundation

@MainActor
public protocol BaseViewModel: AnyObject {
    var isLoading: Bool { get }
    var errorMessage: LocalizedStringResource? { get }

    func setLoading(_ isLoading: Bool)
    func setError(_ message: LocalizedStringResource?)
}

public extension BaseViewModel {
    func perform(_ operation: () async throws -> Void) async {
        setError(nil)
        setLoading(true)
        defer {
            setLoading(false)
        }

        do {
            try await operation()
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else {
                return
            }
            setError(CoreTextsEnum.genericError)
        }
    }
}
