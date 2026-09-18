import Foundation

struct Split: Identifiable, Equatable {
    let id: UUID
    let participantId: UUID
    var amount: Decimal

    init(id: UUID = UUID(), participantId: UUID, amount: Decimal) {
        self.id = id
        self.participantId = participantId
        self.amount = amount
    }
}
