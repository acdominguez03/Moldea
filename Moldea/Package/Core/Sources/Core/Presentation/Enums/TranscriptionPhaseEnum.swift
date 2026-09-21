//
//  TranscriptionPhaseEnum.swift
//  Core
//
//  Created by Andrés on 19/09/2026.
//

import Foundation

enum TranscriptionPhaseEnum: Equatable {
    case idle
    case preparing
    case transcribing
    case failed(LocalizedStringResource)
}
