import Foundation
import FoundationModels
@testable import Core

enum PromptEvalSupport {
    static var isModelAvailable: Bool {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return false }
        return model.supportsLocale(.current)
    }
}
