import Foundation

struct CreateTripInput {
    let name: String
    let startDate: Date
    let endDate: Date
    let participantNames: [String]
    let currentUserName: String
}

struct CreateTripUseCase {
    let tripRepository: TripRepository

    func execute(input: CreateTripInput) throws -> Trip {
        var participants = [Participant(name: input.currentUserName, isCurrentUser: true)]
        for name in input.participantNames where !name.trimmingCharacters(in: .whitespaces).isEmpty {
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            if trimmed.caseInsensitiveCompare(input.currentUserName) != .orderedSame {
                participants.append(Participant(name: trimmed))
            }
        }

        let trip = Trip(
            name: input.name.trimmingCharacters(in: .whitespaces),
            startDate: input.startDate,
            endDate: input.endDate,
            participants: participants
        )
        try tripRepository.save(trip)
        return trip
    }
}
