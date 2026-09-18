import Foundation

enum CurrentUserNameSync {
    /// Renames the current-user participant on every trip to match Settings.
    static func apply(name: String, using repository: TripRepository) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.caseInsensitiveCompare("You") != .orderedSame else { return }

        let trips = try repository.fetchAll()
        for var trip in trips {
            guard let index = trip.participants.firstIndex(where: \.isCurrentUser) else { continue }
            if trip.participants[index].name == trimmed { continue }
            trip.participants[index].name = trimmed
            try repository.save(trip)
        }
    }
}
