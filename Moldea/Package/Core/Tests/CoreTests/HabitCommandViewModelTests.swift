import Testing
import Foundation
@testable import Core

@MainActor
private final class FakeHabitCommandParser: HabitCommandParsing {
    var availability: LanguageModelAvailabilityEnum
    var result: Result<HabitCommandEnum, any Error>
    private(set) var prepareCount = 0
    private(set) var parsedTranscripts: [String] = []

    init(
        availability: LanguageModelAvailabilityEnum = .available,
        result: Result<HabitCommandEnum, any Error> = .success(.listCompleted)
    ) {
        self.availability = availability
        self.result = result
    }

    func prepare() {
        prepareCount += 1
    }

    func parseCommand(in transcript: String, from knownHabits: [Habit]) async throws -> HabitCommandEnum {
        parsedTranscripts.append(transcript)
        return try result.get()
    }
}

@MainActor
private final class FakeHabitsRecognizer: HabitCompletionRecognizing {
    var availability: LanguageModelAvailabilityEnum = .available
    var result: Result<[Habit], any Error>
    private(set) var prepareCount = 0

    var whileResponding: (() -> Void)?

    init(result: Result<[Habit], any Error> = .success([])) {
        self.result = result
    }

    func prepare() {
        prepareCount += 1
    }

    func recognizeCompletions(in transcript: String, from knownHabits: [Habit]) async throws -> [Habit] {
        whileResponding?()
        return try result.get()
    }
}

private struct CreateCall: Sendable, Equatable {
    let name: String
    let color: String
    let icon: String
    let frequency: HabitFrequency
    let repetitionsPerDay: Int
}

private actor FakeCreateHabitUseCase: CreateHabitUseCase {
    private(set) var calls: [CreateCall] = []
    private let error: (any Error)?

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func execute(
        name: String,
        color: String,
        icon: String,
        frequency: HabitFrequency,
        repetitionsPerDay: Int,
        isReminderEnabled: Bool,
        reminderTime: Date,
        isMutedOnWeekends: Bool
    ) async throws {
        calls.append(
            CreateCall(
                name: name,
                color: color,
                icon: icon,
                frequency: frequency,
                repetitionsPerDay: repetitionsPerDay
            )
        )
        if let error { throw error }
    }
}

private actor FakeDeleteHabitUseCase: DeleteHabitUseCase {
    private(set) var ids: [Habit.ID] = []
    private let error: (any Error)?

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func execute(id: Habit.ID) async throws {
        ids.append(id)
        if let error { throw error }
    }
}

private struct UseCaseFailure: Error {}

@MainActor
struct HabitCommandViewModelTests {
    private let leer = makeHabit(name: "Leer")

    private func makeViewModel(
        parser: FakeHabitCommandParser = FakeHabitCommandParser(),
        recognizer: FakeHabitsRecognizer = FakeHabitsRecognizer(),
        createHabitUseCase: FakeCreateHabitUseCase = FakeCreateHabitUseCase(),
        deleteHabitUseCase: FakeDeleteHabitUseCase = FakeDeleteHabitUseCase()
    ) -> HabitCommandViewModel {
        HabitCommandViewModel(
            parser: parser,
            recognizer: recognizer,
            createHabitUseCase: createHabitUseCase,
            deleteHabitUseCase: deleteHabitUseCase
        )
    }

    private var draft: NewHabitDraft {
        NewHabitDraft(
            name: "Correr",
            frequency: .weeklyCount(timesPerWeek: 3),
            repetitionsPerDay: 2
        )
    }

    // MARK: Disponibilidad

    @Test func `Starts parsing`() {
        let viewModel = makeViewModel()

        #expect(viewModel.phase == .parsing)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `Reports the reason when the model is unavailable`() {
        let parser = FakeHabitCommandParser(availability: .unavailable(.deviceNotEligible))

        #expect(makeViewModel(parser: parser).unavailableMessage != nil)
    }

    @Test func `Has no unavailable message when the model is available`() {
        #expect(makeViewModel().unavailableMessage == nil)
    }

    @Test func `Does not ask the model when it is unavailable`() async {
        let parser = FakeHabitCommandParser(availability: .unavailable(.modelNotReady))
        let recognizer = FakeHabitsRecognizer()
        let viewModel = makeViewModel(parser: parser, recognizer: recognizer)

        await viewModel.handle(transcript: "borra leer", knownHabits: [leer])

        #expect(parser.parsedTranscripts.isEmpty)
        #expect(recognizer.prepareCount == 0)
        #expect(viewModel.phase == .parsing)
    }

    // MARK: Crear y borrar

    @Test func `Parsing create moves to its confirmation`() async {
        let expected = draft
        let parser = FakeHabitCommandParser(result: .success(.create(expected)))
        let viewModel = makeViewModel(parser: parser)

        await viewModel.handle(transcript: "crea correr", knownHabits: [])

        #expect(viewModel.phase == .confirmingCreate(expected))
    }

    @Test func `Parsing delete resolves the habit for its confirmation`() async {
        let parser = FakeHabitCommandParser(result: .success(.delete(habitID: leer.id)))
        let viewModel = makeViewModel(parser: parser)

        await viewModel.handle(transcript: "borra leer", knownHabits: [leer])

        #expect(viewModel.phase == .confirmingDelete(leer))
    }

    @Test func `Deleting a habit that is not on the list fails`() async {
        let parser = FakeHabitCommandParser(result: .success(.delete(habitID: UUID())))
        let viewModel = makeViewModel(parser: parser)

        await viewModel.handle(transcript: "borra nadar", knownHabits: [leer])

        #expect(viewModel.phase == .failed)
        #expect(viewModel.errorMessage != nil)
    }

    // MARK: Listar

    @Test func `Listing goes through recognizing and ends recognized`() async {
        let recognizer = FakeHabitsRecognizer(result: .success([leer]))
        let viewModel = makeViewModel(recognizer: recognizer)
        var phaseWhileWorking: HabitCommandPhaseEnum?
        recognizer.whileResponding = { phaseWhileWorking = viewModel.phase }

        await viewModel.handle(transcript: "he leído hoy", knownHabits: [leer])

        #expect(phaseWhileWorking == .recognizing)
        #expect(viewModel.phase == .recognized([leer]))
    }

    @Test func `Listing with no results ends recognized and empty`() async {
        let viewModel = makeViewModel()

        await viewModel.handle(transcript: "hola", knownHabits: [leer])

        #expect(viewModel.phase == .recognized([]))
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `A recognizer error fails with a message`() async {
        let recognizer = FakeHabitsRecognizer(
            result: .failure(LanguageModelErrorEnum.rateLimited)
        )
        let viewModel = makeViewModel(recognizer: recognizer)

        await viewModel.handle(transcript: "he leído hoy", knownHabits: [leer])

        #expect(viewModel.phase == .failed)
        #expect(viewModel.errorMessage != nil)
    }

    // MARK: Errores de parseo

    @Test func `Translates a command error into a message`() async {
        let parser = FakeHabitCommandParser(result: .failure(HabitCommandErrorEnum.notUnderstood))
        let viewModel = makeViewModel(parser: parser)

        await viewModel.handle(transcript: "mmm", knownHabits: [leer])

        #expect(viewModel.phase == .failed)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func `Translates a framework error into a message`() async {
        let parser = FakeHabitCommandParser(result: .failure(LanguageModelErrorEnum.rateLimited))
        let viewModel = makeViewModel(parser: parser)

        await viewModel.handle(transcript: "borra leer", knownHabits: [leer])

        #expect(viewModel.phase == .failed)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func `Stays parsing with no error when cancelled`() async {
        let parser = FakeHabitCommandParser(result: .failure(CancellationError()))
        let viewModel = makeViewModel(parser: parser)

        await viewModel.handle(transcript: "borra leer", knownHabits: [leer])

        #expect(viewModel.phase == .parsing)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: Precalentado

    @Test(arguments: [
        HabitCommandEnum.listCompleted,
        .create(NewHabitDraft(name: "Correr", frequency: .daily, repetitionsPerDay: 1)),
    ])
    func `Prewarms the recognizer when the parse starts`(command: HabitCommandEnum) async {
        let recognizer = FakeHabitsRecognizer()
        let parser = FakeHabitCommandParser(result: .success(command))
        let viewModel = makeViewModel(parser: parser, recognizer: recognizer)

        await viewModel.handle(transcript: "lo que sea", knownHabits: [leer])

        #expect(recognizer.prepareCount == 1)
    }

    // MARK: Confirmación

    @Test func `Creates the habit with the default color and icon`() async {
        let createHabitUseCase = FakeCreateHabitUseCase()
        let parser = FakeHabitCommandParser(result: .success(.create(draft)))
        let viewModel = makeViewModel(parser: parser, createHabitUseCase: createHabitUseCase)

        await viewModel.handle(transcript: "crea correr", knownHabits: [])
        await viewModel.confirm()

        let expected = CreateCall(
            name: "Correr",
            color: HabitAppearanceDefaultsEnum.colorHex,
            icon: HabitAppearanceDefaultsEnum.icon,
            frequency: .weeklyCount(timesPerWeek: 3),
            repetitionsPerDay: 2
        )
        #expect(await createHabitUseCase.calls == [expected])
        #expect(viewModel.phase == .done(.created(draft)))
    }

    @Test func `Deletes the habit the command points to`() async {
        let deleteHabitUseCase = FakeDeleteHabitUseCase()
        let parser = FakeHabitCommandParser(result: .success(.delete(habitID: leer.id)))
        let viewModel = makeViewModel(parser: parser, deleteHabitUseCase: deleteHabitUseCase)

        await viewModel.handle(transcript: "borra leer", knownHabits: [leer])
        await viewModel.confirm()

        #expect(await deleteHabitUseCase.ids == [leer.id])
        #expect(viewModel.phase == .done(.deleted(leer)))
    }

    @Test func `Confirming the recognized list touches no use case`() async {
        let createHabitUseCase = FakeCreateHabitUseCase()
        let deleteHabitUseCase = FakeDeleteHabitUseCase()
        let viewModel = makeViewModel(
            createHabitUseCase: createHabitUseCase,
            deleteHabitUseCase: deleteHabitUseCase
        )

        await viewModel.handle(transcript: "he leído hoy", knownHabits: [leer])
        await viewModel.confirm()

        #expect(await createHabitUseCase.calls.isEmpty)
        #expect(await deleteHabitUseCase.ids.isEmpty)
        #expect(viewModel.phase == .recognized([]))
    }

    @Test func `Confirming while still parsing does nothing`() async {
        let createHabitUseCase = FakeCreateHabitUseCase()
        let viewModel = makeViewModel(createHabitUseCase: createHabitUseCase)

        await viewModel.confirm()

        #expect(await createHabitUseCase.calls.isEmpty)
        #expect(viewModel.phase == .parsing)
    }

    @Test func `Keeps the confirmation and reports the error when creating fails`() async {
        let parser = FakeHabitCommandParser(result: .success(.create(draft)))
        let viewModel = makeViewModel(
            parser: parser,
            createHabitUseCase: FakeCreateHabitUseCase(error: UseCaseFailure())
        )

        await viewModel.handle(transcript: "crea correr", knownHabits: [])
        await viewModel.confirm()

        #expect(viewModel.phase == .confirmingCreate(draft))
        #expect(viewModel.errorMessage != nil)
    }

    @Test func `Keeps the confirmation and reports the error when deleting fails`() async {
        let parser = FakeHabitCommandParser(result: .success(.delete(habitID: leer.id)))
        let viewModel = makeViewModel(
            parser: parser,
            deleteHabitUseCase: FakeDeleteHabitUseCase(error: UseCaseFailure())
        )

        await viewModel.handle(transcript: "borra leer", knownHabits: [leer])
        await viewModel.confirm()

        #expect(viewModel.phase == .confirmingDelete(leer))
        #expect(viewModel.errorMessage != nil)
    }

    // MARK: Cierre automático

    @Test func `Auto dismisses when the list has results`() async {
        let recognizer = FakeHabitsRecognizer(result: .success([leer]))
        let viewModel = makeViewModel(recognizer: recognizer)

        await viewModel.handle(transcript: "he leído hoy", knownHabits: [leer])

        #expect(viewModel.shouldAutoDismiss)
    }

    @Test func `Does not auto dismiss when the list is empty`() async {
        let viewModel = makeViewModel()

        await viewModel.handle(transcript: "hola", knownHabits: [leer])

        #expect(viewModel.shouldAutoDismiss == false)
    }

    @Test func `Does not auto dismiss while confirming a create`() async {
        let draft = NewHabitDraft(name: "Correr", frequency: .daily, repetitionsPerDay: 1)
        let parser = FakeHabitCommandParser(result: .success(.create(draft)))
        let viewModel = makeViewModel(parser: parser)
        #expect(viewModel.shouldAutoDismiss == false)

        await viewModel.handle(transcript: "crea correr", knownHabits: [leer])

        #expect(viewModel.phase == .confirmingCreate(draft))
        #expect(viewModel.shouldAutoDismiss == false)
    }

    @Test func `Does not auto dismiss while confirming a delete`() async {
        let parser = FakeHabitCommandParser(result: .success(.delete(habitID: leer.id)))
        let viewModel = makeViewModel(parser: parser)

        await viewModel.handle(transcript: "borra leer", knownHabits: [leer])

        #expect(viewModel.phase == .confirmingDelete(leer))
        #expect(viewModel.shouldAutoDismiss == false)
    }

    @Test func `Does not auto dismiss after a failure`() async {
        let parser = FakeHabitCommandParser(result: .failure(HabitCommandErrorEnum.notUnderstood))
        let viewModel = makeViewModel(parser: parser)

        await viewModel.handle(transcript: "mmm", knownHabits: [leer])

        #expect(viewModel.phase == .failed)
        #expect(viewModel.shouldAutoDismiss == false)
    }

    // MARK: Reentrada

    @Test func `A second parse clears the previous result`() async {
        let parser = FakeHabitCommandParser(result: .success(.create(draft)))
        let viewModel = makeViewModel(parser: parser)

        await viewModel.handle(transcript: "crea correr", knownHabits: [])
        await viewModel.confirm()
        #expect(viewModel.phase == .done(.created(draft)))

        parser.result = .success(.listCompleted)
        await viewModel.handle(transcript: "he leído hoy", knownHabits: [leer])

        #expect(viewModel.phase == .recognized([]))
        #expect(parser.parsedTranscripts == ["crea correr", "he leído hoy"])
    }
}
