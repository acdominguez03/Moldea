import Testing
import Foundation
import Core
@testable import Habits

private actor FakeHabitRepository: HabitRepository {
    private(set) var deletedIDs: [Habit.ID] = []
    private let error: (any Error)?

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func create(_ habit: Habit) async throws {}

    func delete(id: Habit.ID) async throws {
        if let error { throw error }
        deletedIDs.append(id)
    }

    func setActive(id: Habit.ID, isActive: Bool, updatedAt: Date) async throws {}

    func update(
        id: Habit.ID,
        name: String,
        color: String,
        icon: String,
        schedule: HabitSchedule,
        updatedAt: Date
    ) async throws {}
}

private struct RepositoryFailure: Error, Equatable {}

struct DeleteHabitUseCaseTests {
    @Test func executeDeletesTheHabitWithTheGivenID() async throws {
        let repository = FakeHabitRepository()
        let useCase = DefaultDeleteHabitUseCase(repository: repository)
        let id = UUID()

        try await useCase.execute(id: id)

        #expect(await repository.deletedIDs == [id])
    }

    @Test func executePropagatesRepositoryErrors() async {
        let repository = FakeHabitRepository(error: RepositoryFailure())
        let useCase = DefaultDeleteHabitUseCase(repository: repository)

        await #expect(throws: RepositoryFailure()) {
            try await useCase.execute(id: UUID())
        }
    }
}
