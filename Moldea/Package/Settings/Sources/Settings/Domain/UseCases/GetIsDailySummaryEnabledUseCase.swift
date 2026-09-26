//
//  GetIsDailySummaryEnabledUseCase.swift
//  Settings
//

import Core

protocol GetIsDailySummaryEnabledUseCaseProtocol: Sendable {
    func execute() -> Bool
}

struct GetIsDailySummaryEnabledUseCase: GetIsDailySummaryEnabledUseCaseProtocol {
    private let repository: UserDefaultsRepository

    init(userDefaultsRepository: UserDefaultsRepository) {
        self.repository = userDefaultsRepository
    }

    func execute() -> Bool {
        repository.getBool(PreferenceKey.isDailySummaryEnabled)
    }
}
