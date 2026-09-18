import Foundation
import SwiftData

@MainActor
final class LocalTripRepository: TripRepository, ExpenseRepository, SettlementRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [Trip] {
        let descriptor = FetchDescriptor<TripEntity>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        return try modelContext.fetch(descriptor).map(EntityMapper.toDomain)
    }

    func fetch(id: UUID) throws -> Trip? {
        let descriptor = FetchDescriptor<TripEntity>(predicate: #Predicate { $0.id == id })
        return try modelContext.fetch(descriptor).first.map(EntityMapper.toDomain)
    }

    func save(_ trip: Trip) throws {
        let tripId = trip.id
        let descriptor = FetchDescriptor<TripEntity>(predicate: #Predicate { $0.id == tripId })
        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try modelContext.save()
        }

        let entity = EntityMapper.makeEntity(from: trip)
        modelContext.insert(entity)
        try modelContext.save()
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<TripEntity>(predicate: #Predicate { $0.id == id })
        if let entity = try modelContext.fetch(descriptor).first {
            modelContext.delete(entity)
            try modelContext.save()
        }
    }

    func add(_ expense: Expense, to tripId: UUID) throws {
        guard var trip = try fetch(id: tripId) else { throw TripError.notFound }
        trip.expenses.append(expense)
        try save(trip)
    }

    func update(_ expense: Expense) throws {
        guard var trip = try fetch(id: expense.tripId) else { throw TripError.notFound }
        guard let index = trip.expenses.firstIndex(where: { $0.id == expense.id }) else {
            throw TripError.notFound
        }
        trip.expenses[index] = expense
        try save(trip)
    }

    func delete(expenseId: UUID, tripId: UUID) throws {
        guard var trip = try fetch(id: tripId) else { throw TripError.notFound }
        trip.expenses.removeAll { $0.id == expenseId }
        try save(trip)
    }

    func add(_ settlement: Settlement, to tripId: UUID) throws {
        guard var trip = try fetch(id: tripId) else { throw TripError.notFound }
        trip.settlements.append(settlement)
        try save(trip)
    }
}
