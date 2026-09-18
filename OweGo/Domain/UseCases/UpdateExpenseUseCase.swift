import Foundation

struct UpdateExpenseInput {
    let expense: Expense
    let amount: Decimal
    let description: String
    let category: ExpenseCategory
    let paidByParticipantId: UUID
    let participantIds: [UUID]
    let splitMode: SplitMode
    let notes: String?
    let receiptImageData: Data?
}

struct UpdateExpenseUseCase {
    let tripRepository: TripRepository
    let expenseRepository: ExpenseRepository

    func execute(input: UpdateExpenseInput) throws -> Expense {
        guard let trip = try tripRepository.fetch(id: input.expense.tripId) else {
            throw TripError.notFound
        }

        let participants = trip.participants.filter { input.participantIds.contains($0.id) }
        let splits = BalanceEngine.computeSplits(
            amount: input.amount,
            participants: participants,
            mode: input.splitMode
        )

        var updated = input.expense
        updated.amount = input.amount
        updated.description = input.description
        updated.category = input.category
        updated.paidByParticipantId = input.paidByParticipantId
        updated.splits = splits
        updated.notes = input.notes
        updated.receiptImageData = input.receiptImageData

        try expenseRepository.update(updated)
        return updated
    }
}

struct DeleteExpenseUseCase {
    let expenseRepository: ExpenseRepository

    func execute(expenseId: UUID, tripId: UUID) throws {
        try expenseRepository.delete(expenseId: expenseId, tripId: tripId)
    }
}
