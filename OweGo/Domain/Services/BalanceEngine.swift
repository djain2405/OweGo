import Foundation

enum BalanceEngine {

    // MARK: - Split Calculation

    static func computeSplits(
        amount: Decimal,
        participants: [Participant],
        mode: SplitMode
    ) -> [Split] {
        guard !participants.isEmpty else { return [] }

        switch mode {
        case .equal:
            return equalSplits(amount: amount, participants: participants)
        case .customAmounts(let amounts):
            return customSplits(amounts: amounts)
        case .percentages(let percentages):
            return percentageSplits(amount: amount, percentages: percentages)
        }
    }

    private static func equalSplits(amount: Decimal, participants: [Participant]) -> [Split] {
        let count = Decimal(participants.count)
        let baseShare = (amount / count).rounded(scale: 2, roundingMode: .down)
        var splits = participants.map { Split(participantId: $0.id, amount: baseShare) }
        let allocated = baseShare * count
        let remainder = amount - allocated
        if remainder > 0, let lastIndex = splits.indices.last {
            splits[lastIndex].amount += remainder
        }
        return splits
    }

    private static func customSplits(amounts: [UUID: Decimal]) -> [Split] {
        amounts.map { Split(participantId: $0.key, amount: $0.value) }
    }

    private static func percentageSplits(amount: Decimal, percentages: [UUID: Decimal]) -> [Split] {
        let totalPercentage = percentages.values.reduce(0, +)
        guard totalPercentage > 0 else { return [] }

        var splits: [Split] = []
        var allocated: Decimal = 0
        let sortedEntries = percentages.sorted { $0.key.uuidString < $1.key.uuidString }

        for (index, entry) in sortedEntries.enumerated() {
            let isLast = index == sortedEntries.count - 1
            let share: Decimal
            if isLast {
                share = amount - allocated
            } else {
                share = (amount * entry.value / totalPercentage).rounded(scale: 2, roundingMode: .plain)
                allocated += share
            }
            splits.append(Split(participantId: entry.key, amount: share))
        }
        return splits
    }

    // MARK: - Ledger

    static func computeLedger(for trip: Trip) -> [ParticipantLedger] {
        var paidByParticipant: [UUID: Decimal] = [:]
        var shareByParticipant: [UUID: Decimal] = [:]

        for participant in trip.participants {
            paidByParticipant[participant.id] = 0
            shareByParticipant[participant.id] = 0
        }

        for expense in trip.expenses {
            paidByParticipant[expense.paidByParticipantId, default: 0] += expense.amount
            for split in expense.splits {
                shareByParticipant[split.participantId, default: 0] += split.amount
            }
        }

        var balances: [UUID: Decimal] = [:]
        for participant in trip.participants {
            let paid = paidByParticipant[participant.id, default: 0]
            let share = shareByParticipant[participant.id, default: 0]
            balances[participant.id] = paid - share
        }

        for settlement in trip.settlements {
            balances[settlement.fromParticipantId, default: 0] += settlement.amount
            balances[settlement.toParticipantId, default: 0] -= settlement.amount
        }

        return trip.participants.map { participant in
            let paid = paidByParticipant[participant.id, default: 0]
            let share = shareByParticipant[participant.id, default: 0]
            let balance = balances[participant.id, default: 0]
            return ParticipantLedger(
                participantId: participant.id,
                name: participant.displayName,
                isCurrentUser: participant.isCurrentUser,
                paid: paid,
                share: share,
                balance: balance
            )
        }
    }

    // MARK: - Simplified Debts

    static func computeSimplifiedDebts(
        ledger: [ParticipantLedger],
        threshold: Decimal = 0.01
    ) -> [SimplifiedDebt] {
        struct BalanceEntry {
            let participantId: UUID
            let name: String
            var amount: Decimal
        }

        var creditors: [BalanceEntry] = []
        var debtors: [BalanceEntry] = []

        for entry in ledger {
            if entry.balance > threshold {
                creditors.append(BalanceEntry(
                    participantId: entry.participantId,
                    name: entry.name,
                    amount: entry.balance
                ))
            } else if entry.balance < -threshold {
                debtors.append(BalanceEntry(
                    participantId: entry.participantId,
                    name: entry.name,
                    amount: -entry.balance
                ))
            }
        }

        creditors.sort { $0.amount > $1.amount }
        debtors.sort { $0.amount > $1.amount }

        var debts: [SimplifiedDebt] = []
        var creditorIndex = 0
        var debtorIndex = 0

        while creditorIndex < creditors.count && debtorIndex < debtors.count {
            let transfer = min(creditors[creditorIndex].amount, debtors[debtorIndex].amount)
            if transfer > threshold {
                debts.append(SimplifiedDebt(
                    fromParticipantId: debtors[debtorIndex].participantId,
                    fromName: debtors[debtorIndex].name,
                    toParticipantId: creditors[creditorIndex].participantId,
                    toName: creditors[creditorIndex].name,
                    amount: transfer.rounded(scale: 2, roundingMode: .plain)
                ))
            }
            creditors[creditorIndex].amount -= transfer
            debtors[debtorIndex].amount -= transfer
            if creditors[creditorIndex].amount <= threshold { creditorIndex += 1 }
            if debtors[debtorIndex].amount <= threshold { debtorIndex += 1 }
        }

        return debts
    }

    static func computeSummary(for trip: Trip) -> TripBalanceSummary {
        let ledger = computeLedger(for: trip)
        let debts = computeSimplifiedDebts(ledger: ledger)
        return TripBalanceSummary(
            ledgers: ledger,
            simplifiedDebts: debts,
            totalSpent: trip.totalSpent,
            expenseCount: trip.expenses.count,
            remainingDebtCount: debts.count
        )
    }
}

private extension Decimal {
    func rounded(scale: Int, roundingMode: NSDecimalNumber.RoundingMode) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, roundingMode)
        return result
    }
}
