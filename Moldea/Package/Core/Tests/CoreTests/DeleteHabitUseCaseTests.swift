import Testing
import Foundation
@testable import Core

struct DeleteHabitUseCaseTests {
    @Test func `Delegates the id to the repository`() async throws {
        let repository = FakeHabitRepository()
        let useCase = DefaultDeleteHabitUseCase(repository: repository)
        let id = UUID()

        try await useCase.execute(id: id)

        #expect(await repository.deleted == [id])
    }

    @Test func `Propagates repository errors`() async {
        let repository = FakeHabitRepository(error: RepositoryFailure())
        let useCase = DefaultDeleteHabitUseCase(repository: repository)

        await #expect(throws: RepositoryFailure()) {
            try await useCase.execute(id: UUID())
        }
    }
}
