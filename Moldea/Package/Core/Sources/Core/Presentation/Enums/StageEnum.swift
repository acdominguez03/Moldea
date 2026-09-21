//
//  StageEnum.swift
//  Core
//
//  Created by Andrés on 19/09/2026.
//

import Foundation

enum StageEnum: String {
    case permission
    case deviceSupport
    case assets
    case audioFormat
    case audioEngine
    case analysis

    var label: LocalizedStringResource {
        switch self {
        case .permission: CoreTextsEnum.transcriptionStagePermission
        case .deviceSupport: CoreTextsEnum.transcriptionStageDeviceSupport
        case .assets: CoreTextsEnum.transcriptionStageAssets
        case .audioFormat: CoreTextsEnum.transcriptionStageAudioFormat
        case .audioEngine: CoreTextsEnum.transcriptionStageAudioEngine
        case .analysis: CoreTextsEnum.transcriptionStageAnalysis
        }
    }
}
