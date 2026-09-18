import Foundation

struct Settlement: Identifiable, Equatable {
    let id: UUID
    let tripId: UUID
    let fromParticipantId: UUID
    let toParticipantId: UUID
    var amount: Decimal
    var settledAt: Date

    init(
        id: UUID = UUID(),
        tripId: UUID,
        fromParticipantId: UUID,
        toParticipantId: UUID,
        amount: Decimal,
        settledAt: Date = Date()
    ) {
        self.id = id
        self.tripId = tripId
        self.fromParticipantId = fromParticipantId
        self.toParticipantId = toParticipantId
        self.amount = amount
        self.settledAt = settledAt
    }
}
