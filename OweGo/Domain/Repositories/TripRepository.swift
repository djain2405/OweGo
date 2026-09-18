import Foundation

protocol TripRepository {
    func fetchAll() throws -> [Trip]
    func fetch(id: UUID) throws -> Trip?
    func save(_ trip: Trip) throws
    func delete(id: UUID) throws
}

protocol ExpenseRepository {
    func add(_ expense: Expense, to tripId: UUID) throws
    func update(_ expense: Expense) throws
    func delete(expenseId: UUID, tripId: UUID) throws
}

protocol SettlementRepository {
    func add(_ settlement: Settlement, to tripId: UUID) throws
}
