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
        result: Result<HabitCommandEnum, any Error> = .success(
            .complete(habitIDs: [])
        )
    ) {
        self.availability = availability
        self.result = result
    }

    func prepare() {
        prepareCount += 1
    }

    func parseCommand(
        in transcript: String,
        from knownHabits: [Habit],
        today todayHabits: [TodayHabit]
    ) async throws -> HabitCommandEnum {
        parsedTranscripts.append(transcript)
        return try result.get()
    }
}

private actor FakeCompleteHabitsUseCase: CompleteHabitsUseCase {
    private(set) var calls: [[Habit.ID]] = []
    private let alreadyCompleted: Set<Habit.ID>
    private let error: (any Error)?

    init(alreadyCompleted: Set<Habit.ID> = [], error: (any Error)? = nil) {
        self.alreadyCompleted = alreadyCompleted
        self.error = error
    }

    func execute(habitIDs: [Habit.ID], in todayHabits: [TodayHabit]) async throws -> CompleteHabitsResult {
        calls.append(habitIDs)
        if let error { throw error }
        return CompleteHabitsResult(
            completed: habitIDs.filter { !alreadyCompleted.contains($0) },
            alreadyCompleted: habitIDs.filter { alreadyCompleted.contains($0) }
        )
    }
}

private actor FakeGetTodayHabitsUseCase: GetTodayHabitsUseCase {
    private let habits: [TodayHabit]

    init(habits: [TodayHabit]) {
        self.habits = habits
    }

    func execute(on day: Date) async throws -> [TodayHabit] {
        habits
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
    private let correr = makeHabit(name: "Correr")

    private var todayHabits: [TodayHabit] {
        [leer, correr].map { TodayHabit(habit: $0, completions: [], referenceDay: .now) }
    }

    private func makeViewModel(
        parser: FakeHabitCommandParser = FakeHabitCommandParser(),
        createHabitUseCase: FakeCreateHabitUseCase = FakeCreateHabitUseCase(),
        deleteHabitUseCase: FakeDeleteHabitUseCase = FakeDeleteHabitUseCase(),
        completeHabitsUseCase: FakeCompleteHabitsUseCase = FakeCompleteHabitsUseCase()
    ) -> HabitCommandViewModel {
        HabitCommandViewModel(
            parser: parser,
            createHabitUseCase: createHabitUseCase,
            deleteHabitUseCase: deleteHabitUseCase,
            completeHabitsUseCase: completeHabitsUseCase,
            getTodayHabitsUseCase: FakeGetTodayHabitsUseCase(habits: todayHabits)
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
        let viewModel = makeViewModel(parser: parser)

        await viewModel.handle(transcript: "borra leer", knownHabits: [leer])

        #expect(parser.parsedTranscripts.isEmpty)
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

    // MARK: Completar

    @Test func `Completing saves the habits and ends done`() async {
        let completeHabitsUseCase = FakeCompleteHabitsUseCase()
        let parser = FakeHabitCommandParser(
            result: .success(.complete(habitIDs: [leer.id, correr.id]))
        )
        let viewModel = makeViewModel(parser: parser, completeHabitsUseCase: completeHabitsUseCase)

        await viewModel.handle(transcript: "he leído y he corrido", knownHabits: [leer, correr])

        #expect(await completeHabitsUseCase.calls == [[leer.id, correr.id]])
        #expect(viewModel.phase == .done(.completed(completed: [leer, correr], alreadyCompleted: [])))
    }

    @Test func `Shows the already completed habits the use case reports apart`() async {
        let completeHabitsUseCase = FakeCompleteHabitsUseCase(alreadyCompleted: [leer.id])
        let parser = FakeHabitCommandParser(
            result: .success(.complete(habitIDs: [leer.id, correr.id]))
        )
        let viewModel = makeViewModel(parser: parser, completeHabitsUseCase: completeHabitsUseCase)

        await viewModel.handle(transcript: "he leído y he corrido", knownHabits: [leer, correr])

        #expect(await completeHabitsUseCase.calls == [[leer.id, correr.id]])
        #expect(viewModel.phase == .done(.completed(completed: [correr], alreadyCompleted: [leer])))
    }

    @Test func `Mentioning no habit fails with a message and saves nothing`() async {
        let completeHabitsUseCase = FakeCompleteHabitsUseCase()
        let viewModel = makeViewModel(completeHabitsUseCase: completeHabitsUseCase)

        await viewModel.handle(transcript: "he nadado", knownHabits: [leer])

        #expect(await completeHabitsUseCase.calls.isEmpty)
        #expect(viewModel.phase == .failed)
        #expect(viewModel.errorMessage == CoreTextsEnum.aiNoHabitsRecognized)
    }

    @Test func `Ignores ids that are not habits of today`() async {
        let parser = FakeHabitCommandParser(
            result: .success(.complete(habitIDs: [UUID()]))
        )
        let viewModel = makeViewModel(parser: parser)

        await viewModel.handle(transcript: "he nadado", knownHabits: [leer])

        #expect(viewModel.phase == .failed)
    }

    @Test func `A complete use case error fails with a message`() async {
        let parser = FakeHabitCommandParser(
            result: .success(.complete(habitIDs: [leer.id]))
        )
        let viewModel = makeViewModel(
            parser: parser,
            completeHabitsUseCase: FakeCompleteHabitsUseCase(error: UseCaseFailure())
        )

        await viewModel.handle(transcript: "he leído", knownHabits: [leer])

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

    @Test func `Confirming after completing touches no other use case`() async {
        let createHabitUseCase = FakeCreateHabitUseCase()
        let deleteHabitUseCase = FakeDeleteHabitUseCase()
        let parser = FakeHabitCommandParser(
            result: .success(.complete(habitIDs: [leer.id]))
        )
        let viewModel = makeViewModel(
            parser: parser,
            createHabitUseCase: createHabitUseCase,
            deleteHabitUseCase: deleteHabitUseCase
        )

        await viewModel.handle(transcript: "he leído hoy", knownHabits: [leer])
        await viewModel.confirm()

        #expect(await createHabitUseCase.calls.isEmpty)
        #expect(await deleteHabitUseCase.ids.isEmpty)
        #expect(viewModel.phase == .done(.completed(completed: [leer], alreadyCompleted: [])))
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

    @Test func `Auto dismisses after completing habits`() async {
        let parser = FakeHabitCommandParser(
            result: .success(.complete(habitIDs: [leer.id]))
        )
        let viewModel = makeViewModel(parser: parser)

        await viewModel.handle(transcript: "he leído hoy", knownHabits: [leer])

        #expect(viewModel.shouldAutoDismiss)
    }

    @Test func `Does not auto dismiss when a habit was already completed`() async {
        let parser = FakeHabitCommandParser(
            result: .success(.complete(habitIDs: [correr.id, leer.id]))
        )
        let viewModel = makeViewModel(
            parser: parser,
            completeHabitsUseCase: FakeCompleteHabitsUseCase(alreadyCompleted: [leer.id])
        )

        await viewModel.handle(transcript: "he leído y he corrido", knownHabits: [leer, correr])

        #expect(viewModel.shouldAutoDismiss == false)
    }

    @Test func `Does not auto dismiss when no habit was mentioned`() async {
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

        parser.result = .success(.complete(habitIDs: [leer.id]))
        await viewModel.handle(transcript: "he leído hoy", knownHabits: [leer])

        #expect(viewModel.phase == .done(.completed(completed: [leer], alreadyCompleted: [])))
        #expect(parser.parsedTranscripts == ["crea correr", "he leído hoy"])
    }
}
