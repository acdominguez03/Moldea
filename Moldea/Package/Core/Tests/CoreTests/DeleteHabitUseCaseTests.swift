import Testing
import Foundation
@testable import Core

struct DeleteHabitUseCaseTests {
    @Test func executeDeletesTheHabitWithTheGivenID() async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = DefaultDeleteHabitUseCase(repository: repository, notificationScheduler: scheduler)
        let id = UUID()

        try await useCase.execute(id: id)

        #expect(await repository.deleted == [id])
    }

    @Test func executeCancelsPendingReminders() async throws {
        let repository = FakeHabitRepository()
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = DefaultDeleteHabitUseCase(repository: repository, notificationScheduler: scheduler)
        let id = UUID()

        try await useCase.execute(id: id)

        #expect(await scheduler.cancelledHabitIDs == [id])
    }

    @Test func executePropagatesRepositoryErrorsWithoutCancellingReminders() async {
        let repository = FakeHabitRepository(error: RepositoryFailure())
        let scheduler = FakeHabitNotificationScheduler()
        let useCase = DefaultDeleteHabitUseCase(repository: repository, notificationScheduler: scheduler)

        await #expect(throws: RepositoryFailure()) {
            try await useCase.execute(id: UUID())
        }
        #expect(await scheduler.cancelledHabitIDs.isEmpty)
    }
}
