import Foundation

struct AddExpenseInput {
    let tripId: UUID
    let amount: Decimal
    let description: String
    let category: ExpenseCategory
    let paidByParticipantId: UUID
    let participantIds: [UUID]
    let splitMode: SplitMode
    let notes: String?
    let receiptImageData: Data?
}

struct AddExpenseUseCase {
    let tripRepository: TripRepository
    let expenseRepository: ExpenseRepository

    func execute(input: AddExpenseInput) throws -> Expense {
        guard let trip = try tripRepository.fetch(id: input.tripId) else {
            throw TripError.notFound
        }

        let participants = trip.participants.filter { input.participantIds.contains($0.id) }
        let splits = BalanceEngine.computeSplits(
            amount: input.amount,
            participants: participants,
            mode: input.splitMode
        )

        let expense = Expense(
            tripId: input.tripId,
            amount: input.amount,
            description: input.description,
            category: input.category,
            paidByParticipantId: input.paidByParticipantId,
            splits: splits,
            notes: input.notes,
            receiptImageData: input.receiptImageData
        )

        try expenseRepository.add(expense, to: input.tripId)
        return expense
    }
}

enum TripError: LocalizedError {
    case notFound
    case invalidInput(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Trip not found."
        case .invalidInput(let message):
            return message
        }
    }
}
