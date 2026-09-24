import Foundation

enum TripStoryHelpers {
    struct ExpenseMoment: Equatable {
        let expense: Expense
        let title: String
        let payerName: String
        let amount: Decimal
        /// Participant's share when scoped to a person; otherwise full amount.
        let relevantAmount: Decimal
    }

    static func expenseTitle(_ expense: Expense) -> String {
        expense.description.isEmpty ? expense.category.rawValue : expense.description
    }

    static func payerName(for expense: Expense, in trip: Trip) -> String {
        trip.participants.first(where: { $0.id == expense.paidByParticipantId })?.displayName ?? "Someone"
    }

    static func largestExpense(on trip: Trip) -> ExpenseMoment? {
        guard let expense = trip.expenses.max(by: { $0.amount < $1.amount }) else { return nil }
        return moment(for: expense, in: trip, relevantAmount: expense.amount)
    }

    /// Top expenses by total amount (for group “why”).
    static func topExpenses(on trip: Trip, limit: Int) -> [ExpenseMoment] {
        Array(allExpenses(on: trip).prefix(limit))
    }

    /// Every expense on the trip, largest first (for full group reports).
    static func allExpenses(on trip: Trip) -> [ExpenseMoment] {
        trip.expenses
            .sorted { $0.amount > $1.amount }
            .map { moment(for: $0, in: trip, relevantAmount: $0.amount) }
    }

    /// Expenses involving a participant, ranked by their split amount.
    static func topExpenses(
        involving participantId: UUID,
        on trip: Trip,
        limit: Int
    ) -> [ExpenseMoment] {
        Array(expenses(involving: participantId, on: trip).prefix(limit))
    }

    /// All expenses involving a participant, ranked by their share.
    static func expenses(involving participantId: UUID, on trip: Trip) -> [ExpenseMoment] {
        trip.expenses
            .compactMap { expense -> ExpenseMoment? in
                guard expense.involves(participantId) else { return nil }
                let share = expense.splits.first(where: { $0.participantId == participantId })?.amount
                    ?? (expense.paidByParticipantId == participantId ? expense.amount : 0)
                return moment(for: expense, in: trip, relevantAmount: share)
            }
            .sorted { $0.relevantAmount > $1.relevantAmount }
    }

    /// Largest expense both people are on (for debt card subtitle).
    static func pairContextSubtitle(
        fromParticipantId: UUID,
        toParticipantId: UUID,
        on trip: Trip
    ) -> String? {
        let shared = trip.expenses.filter {
            $0.involves(fromParticipantId) && $0.involves(toParticipantId)
        }
        guard let biggest = shared.max(by: { $0.amount < $1.amount }) else { return nil }
        let title = expenseTitle(biggest).lowercased()
        return "Mostly \(title)"
    }

    /// Short “Mostly gas + groceries” from top 2 category/titles for a participant.
    static func mostlyPhrase(for participantId: UUID, on trip: Trip) -> String? {
        let top = topExpenses(involving: participantId, on: trip, limit: 2)
        guard !top.isEmpty else { return nil }
        let labels = top.map { $0.title.lowercased() }
        if labels.count == 1 {
            return "Mostly \(labels[0])"
        }
        return "Mostly \(labels[0]) + \(labels[1])"
    }

    static func whoFrontedMost(summary: TripBalanceSummary) -> ParticipantLedger? {
        guard let fronter = summary.ledgers.max(by: { $0.paid < $1.paid }), fronter.paid > 0 else {
            return nil
        }
        return fronter
    }

    // MARK: - Private

    private static func moment(for expense: Expense, in trip: Trip, relevantAmount: Decimal) -> ExpenseMoment {
        ExpenseMoment(
            expense: expense,
            title: expenseTitle(expense),
            payerName: payerName(for: expense, in: trip),
            amount: expense.amount,
            relevantAmount: relevantAmount
        )
    }
}

extension Expense {
    func involves(_ participantId: UUID) -> Bool {
        paidByParticipantId == participantId
            || splits.contains { $0.participantId == participantId }
    }
}
