import Foundation

struct RecordSettlementInput {
    let tripId: UUID
    let fromParticipantId: UUID
    let toParticipantId: UUID
    let amount: Decimal
}

struct RecordSettlementUseCase {
    let tripRepository: TripRepository
    let settlementRepository: SettlementRepository

    func execute(input: RecordSettlementInput) throws -> Settlement {
        guard try tripRepository.fetch(id: input.tripId) != nil else {
            throw TripError.notFound
        }
        guard input.amount > 0 else {
            throw TripError.invalidInput("Settlement amount must be greater than zero.")
        }

        let settlement = Settlement(
            tripId: input.tripId,
            fromParticipantId: input.fromParticipantId,
            toParticipantId: input.toParticipantId,
            amount: input.amount
        )
        try settlementRepository.add(settlement, to: input.tripId)
        return settlement
    }
}

struct EndTripUseCase {
    let tripRepository: TripRepository

    func execute(tripId: UUID) throws -> Trip {
        guard var trip = try tripRepository.fetch(id: tripId) else {
            throw TripError.notFound
        }
        trip.isEnded = true
        try tripRepository.save(trip)
        return trip
    }
}
