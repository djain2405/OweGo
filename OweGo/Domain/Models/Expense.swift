import Foundation

struct Expense: Identifiable, Equatable {
    let id: UUID
    let tripId: UUID
    var amount: Decimal
    var description: String
    var category: ExpenseCategory
    var paidByParticipantId: UUID
    var splits: [Split]
    var notes: String?
    var receiptImageData: Data?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        tripId: UUID,
        amount: Decimal,
        description: String = "",
        category: ExpenseCategory = .other,
        paidByParticipantId: UUID,
        splits: [Split],
        notes: String? = nil,
        receiptImageData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.tripId = tripId
        self.amount = amount
        self.description = description
        self.category = category
        self.paidByParticipantId = paidByParticipantId
        self.splits = splits
        self.notes = notes
        self.receiptImageData = receiptImageData
        self.createdAt = createdAt
    }
}
