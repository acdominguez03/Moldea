import Testing
import FoundationModels
@testable import Core

private struct UnknownFailure: Error {}

struct FoundationModelsErrorMapperTests {
    @Test(arguments: [
        (SystemLanguageModel.Availability.UnavailableReason.deviceNotEligible,
         LanguageModelUnavailableReasonEnum.deviceNotEligible),
        (.appleIntelligenceNotEnabled, .appleIntelligenceNotEnabled),
        (.modelNotReady, .modelNotReady),
    ])
    func `Maps every unavailable reason`(
        reason: SystemLanguageModel.Availability.UnavailableReason,
        expected: LanguageModelUnavailableReasonEnum
    ) {
        #expect(FoundationModelsErrorMapper.unavailableReason(for: reason) == expected)
    }

    @Test func `Maps a rate limited generation error`() {
        let error = LanguageModelSession.GenerationError.rateLimited(
            .init(debugDescription: "")
        )

        #expect(FoundationModelsErrorMapper.languageModelError(for: error) == .rateLimited)
    }

    @Test func `Maps an exceeded context window to the context size error`() {
        let error = LanguageModelSession.GenerationError.exceededContextWindowSize(
            .init(debugDescription: "")
        )

        #expect(FoundationModelsErrorMapper.languageModelError(for: error) == .contextSizeExceeded)
    }

    @Test func `Maps unavailable assets`() {
        let error = LanguageModelSession.GenerationError.assetsUnavailable(
            .init(debugDescription: "")
        )

        #expect(FoundationModelsErrorMapper.languageModelError(for: error) == .assetsUnavailable)
    }

    @Test func `Maps an unsupported locale`() {
        let error = LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(
            .init(debugDescription: "")
        )

        #expect(FoundationModelsErrorMapper.languageModelError(for: error) == .localeNotSupported)
    }

    @Test func `Maps a schema error to a generation failure`() {
        let error = GenerationSchema.SchemaError.emptyTypeChoices(
            schema: "HabitName",
            context: .init(debugDescription: "")
        )

        #expect(FoundationModelsErrorMapper.languageModelError(for: error) == .generationFailed)
    }

    @Test func `Falls back to a generation failure for an unknown error`() {
        #expect(FoundationModelsErrorMapper.languageModelError(for: UnknownFailure()) == .generationFailed)
    }
}
