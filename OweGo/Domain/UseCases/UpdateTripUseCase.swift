import Foundation

struct EditableParticipant: Identifiable, Equatable {
    let id: UUID
    var name: String
    var isCurrentUser: Bool
    var isNew: Bool

    init(from participant: Participant, isNew: Bool = false) {
        self.id = participant.id
        self.name = participant.name
        self.isCurrentUser = participant.isCurrentUser
        self.isNew = isNew
    }

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.isCurrentUser = false
        self.isNew = true
    }

    func toParticipant() -> Participant {
        Participant(id: id, name: name.trimmingCharacters(in: .whitespaces), isCurrentUser: isCurrentUser)
    }
}

struct UpdateTripInput {
    let tripId: UUID
    let name: String
    let startDate: Date
    let endDate: Date
    let participants: [EditableParticipant]
}

struct UpdateTripUseCase {
    let tripRepository: TripRepository

    func execute(input: UpdateTripInput) throws -> Trip {
        guard var trip = try tripRepository.fetch(id: input.tripId) else {
            throw TripError.notFound
        }

        let trimmedName = input.name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw TripError.invalidInput("Trip name is required.")
        }

        let updatedParticipants = try mergeParticipants(
            existing: trip.participants,
            edited: input.participants,
            trip: trip
        )

        trip.name = trimmedName
        trip.startDate = input.startDate
        trip.endDate = input.endDate
        trip.participants = updatedParticipants

        try tripRepository.save(trip)
        return trip
    }

    private func mergeParticipants(
        existing: [Participant],
        edited: [EditableParticipant],
        trip: Trip
    ) throws -> [Participant] {
        let editedIds = Set(edited.map(\.id))
        let removed = existing.filter { !editedIds.contains($0.id) }

        for participant in removed {
            if isParticipantReferenced(participant.id, in: trip) {
                throw TripError.invalidInput("\(participant.name) has expenses on this trip and can't be removed.")
            }
        }

        var result: [Participant] = []
        for editable in edited {
            let name = editable.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            if editable.isCurrentUser || existing.contains(where: { $0.id == editable.id && $0.isCurrentUser }) {
                result.append(Participant(id: editable.id, name: name, isCurrentUser: true))
            } else {
                result.append(Participant(id: editable.id, name: name))
            }
        }

        guard result.contains(where: \.isCurrentUser) else {
            throw TripError.invalidInput("You must remain a participant on the trip.")
        }

        return result
    }

    private func isParticipantReferenced(_ participantId: UUID, in trip: Trip) -> Bool {
        if trip.expenses.contains(where: { $0.paidByParticipantId == participantId }) {
            return true
        }
        if trip.expenses.contains(where: { $0.splits.contains(where: { $0.participantId == participantId }) }) {
            return true
        }
        if trip.settlements.contains(where: {
            $0.fromParticipantId == participantId || $0.toParticipantId == participantId
        }) {
            return true
        }
        return false
    }
}

struct DeleteTripUseCase {
    let tripRepository: TripRepository

    func execute(tripId: UUID) throws {
        guard try tripRepository.fetch(id: tripId) != nil else {
            throw TripError.notFound
        }
        try tripRepository.delete(id: tripId)
    }
}
