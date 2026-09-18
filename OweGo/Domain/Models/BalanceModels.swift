import Foundation

struct ParticipantLedger: Identifiable, Equatable {
    let participantId: UUID
    let name: String
    let isCurrentUser: Bool
    let paid: Decimal
    let share: Decimal
    let balance: Decimal

    var id: UUID { participantId }
}

struct SimplifiedDebt: Identifiable, Equatable {
    let fromParticipantId: UUID
    let fromName: String
    let toParticipantId: UUID
    let toName: String
    let amount: Decimal

    var id: String { "\(fromParticipantId)-\(toParticipantId)" }
}

struct TripBalanceSummary: Equatable {
    let ledgers: [ParticipantLedger]
    let simplifiedDebts: [SimplifiedDebt]
    let totalSpent: Decimal
    let expenseCount: Int
    let remainingDebtCount: Int

    var isFullySettled: Bool {
        simplifiedDebts.isEmpty
    }
}
