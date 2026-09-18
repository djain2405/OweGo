import Foundation
import SwiftData

@Model
final class TripEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var isEnded: Bool
    @Relationship(deleteRule: .cascade, inverse: \ParticipantEntity.trip)
    var participants: [ParticipantEntity]
    @Relationship(deleteRule: .cascade, inverse: \ExpenseEntity.trip)
    var expenses: [ExpenseEntity]
    @Relationship(deleteRule: .cascade, inverse: \SettlementEntity.trip)
    var settlements: [SettlementEntity]

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        isEnded: Bool = false,
        participants: [ParticipantEntity] = [],
        expenses: [ExpenseEntity] = [],
        settlements: [SettlementEntity] = []
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.isEnded = isEnded
        self.participants = participants
        self.expenses = expenses
        self.settlements = settlements
    }
}

@Model
final class ParticipantEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var isCurrentUser: Bool
    var trip: TripEntity?

    init(id: UUID = UUID(), name: String, isCurrentUser: Bool = false, trip: TripEntity? = nil) {
        self.id = id
        self.name = name
        self.isCurrentUser = isCurrentUser
        self.trip = trip
    }
}

@Model
final class ExpenseEntity {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var expenseDescription: String
    var categoryRaw: String
    var paidByParticipantId: UUID
    var notes: String?
    @Attribute(.externalStorage) var receiptImageData: Data?
    var createdAt: Date
    var trip: TripEntity?
    @Relationship(deleteRule: .cascade, inverse: \SplitEntity.expense)
    var splits: [SplitEntity]

    init(
        id: UUID = UUID(),
        amount: Decimal,
        expenseDescription: String = "",
        categoryRaw: String = ExpenseCategory.other.rawValue,
        paidByParticipantId: UUID,
        notes: String? = nil,
        receiptImageData: Data? = nil,
        createdAt: Date = Date(),
        trip: TripEntity? = nil,
        splits: [SplitEntity] = []
    ) {
        self.id = id
        self.amount = amount
        self.expenseDescription = expenseDescription
        self.categoryRaw = categoryRaw
        self.paidByParticipantId = paidByParticipantId
        self.notes = notes
        self.receiptImageData = receiptImageData
        self.createdAt = createdAt
        self.trip = trip
        self.splits = splits
    }
}

@Model
final class SplitEntity {
    @Attribute(.unique) var id: UUID
    var participantId: UUID
    var amount: Decimal
    var expense: ExpenseEntity?

    init(id: UUID = UUID(), participantId: UUID, amount: Decimal, expense: ExpenseEntity? = nil) {
        self.id = id
        self.participantId = participantId
        self.amount = amount
        self.expense = expense
    }
}

@Model
final class SettlementEntity {
    @Attribute(.unique) var id: UUID
    var fromParticipantId: UUID
    var toParticipantId: UUID
    var amount: Decimal
    var settledAt: Date
    var trip: TripEntity?

    init(
        id: UUID = UUID(),
        fromParticipantId: UUID,
        toParticipantId: UUID,
        amount: Decimal,
        settledAt: Date = Date(),
        trip: TripEntity? = nil
    ) {
        self.id = id
        self.fromParticipantId = fromParticipantId
        self.toParticipantId = toParticipantId
        self.amount = amount
        self.settledAt = settledAt
        self.trip = trip
    }
}
