//
//  TranscriberEnum.swift
//  Core
//
//  Created by Andrés on 19/09/2026.
//

import Speech

enum TranscriberEnum {
    case speech(SpeechTranscriber)
    case dictation(DictationTranscriber)
    
    var module: any SpeechModule {
        switch self {
        case .speech(let module): module
        case .dictation(let module): module
        }
    }
}
