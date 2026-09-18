import Foundation

struct Trip: Identifiable, Equatable {
    let id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var participants: [Participant]
    var expenses: [Expense]
    var settlements: [Settlement]
    var isEnded: Bool

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        participants: [Participant] = [],
        expenses: [Expense] = [],
        settlements: [Settlement] = [],
        isEnded: Bool = false
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.participants = participants
        self.expenses = expenses
        self.settlements = settlements
        self.isEnded = isEnded
    }

    var isActive: Bool {
        guard !isEnded else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return today >= start && today <= end
    }

    var isPast: Bool {
        if isEnded { return true }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: endDate)
        return today > end
    }

    var currentUser: Participant? {
        participants.first(where: \.isCurrentUser)
    }

    var totalSpent: Decimal {
        expenses.reduce(0) { $0 + $1.amount }
    }
}
