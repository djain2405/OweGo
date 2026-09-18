import XCTest
@testable import OweGo

final class BalanceEngineTests: XCTestCase {

    // MARK: - PRD Example

    func testLedgerWithMultipleExpenses() {
        let divya = Participant(name: "Divya", isCurrentUser: true)
        let gabe = Participant(name: "Gabe")
        let sarah = Participant(name: "Sarah")
        let bennett = Participant(name: "Bennett")
        let participants = [divya, gabe, sarah, bennett]
        let tripId = UUID()

        let trip = Trip(
            id: tripId,
            name: "Mt. Whitney",
            startDate: Date(),
            endDate: Date(),
            participants: participants,
            expenses: [
                makeEqualExpense(tripId: tripId, amount: 400, payer: divya, participants: participants),
                makeEqualExpense(tripId: tripId, amount: 120, payer: gabe, participants: participants),
                makeEqualExpense(tripId: tripId, amount: 80, payer: sarah, participants: participants),
                makeEqualExpense(tripId: tripId, amount: 180, payer: bennett, participants: participants)
            ]
        )

        let ledger = BalanceEngine.computeLedger(for: trip)
        XCTAssertEqual(ledger.map(\.paid).reduce(0, +), 780)
        XCTAssertEqual(ledger.map(\.share).reduce(0, +), 780)
        XCTAssertEqual(ledger.map(\.balance).reduce(0, +), 0)
    }

    func testSimplifiedDebtsFromPRDBalances() {
        let ledger = [
            ParticipantLedger(participantId: UUID(), name: "Divya", isCurrentUser: true, paid: 482, share: 194, balance: 288),
            ParticipantLedger(participantId: UUID(), name: "Gabe", isCurrentUser: false, paid: 120, share: 222, balance: -102),
            ParticipantLedger(participantId: UUID(), name: "Sarah", isCurrentUser: false, paid: 70, share: 164, balance: -94),
            ParticipantLedger(participantId: UUID(), name: "Bennett", isCurrentUser: false, paid: 108, share: 200, balance: -92)
        ]

        let debts = BalanceEngine.computeSimplifiedDebts(ledger: ledger)
        XCTAssertEqual(debts.count, 3)
        XCTAssertEqual(debts.map(\.amount).reduce(0, +), 288)
    }

    // MARK: - Split Modes

    func testEqualSplitDistributesRemainderToLastParticipant() {
        let a = Participant(name: "A")
        let b = Participant(name: "B")
        let c = Participant(name: "C")

        let splits = BalanceEngine.computeSplits(amount: 10, participants: [a, b, c], mode: .equal)
        XCTAssertEqual(splits.count, 3)
        XCTAssertEqual(splits.map(\.amount).reduce(0, +), 10)
        // 10 / 3 → 3.33, 3.33, 3.34 (remainder to last)
        XCTAssertEqual(splits[0].amount, Decimal(string: "3.33"))
        XCTAssertEqual(splits[1].amount, Decimal(string: "3.33"))
        XCTAssertEqual(splits[2].amount, Decimal(string: "3.34"))
    }

    func testEqualSplitPennyCaseWithTwoPeople() {
        let a = Participant(name: "A")
        let b = Participant(name: "B")
        let splits = BalanceEngine.computeSplits(amount: Decimal(string: "0.03")!, participants: [a, b], mode: .equal)
        XCTAssertEqual(splits.map(\.amount).reduce(0, +), Decimal(string: "0.03"))
        XCTAssertEqual(splits[0].amount, Decimal(string: "0.01"))
        XCTAssertEqual(splits[1].amount, Decimal(string: "0.02"))
    }

    func testCustomAmountSplit() {
        let a = Participant(name: "A")
        let b = Participant(name: "B")
        let splits = BalanceEngine.computeSplits(
            amount: 100,
            participants: [a, b],
            mode: .customAmounts([a.id: 70, b.id: 30])
        )
        XCTAssertEqual(splits.first { $0.participantId == a.id }?.amount, 70)
        XCTAssertEqual(splits.first { $0.participantId == b.id }?.amount, 30)
    }

    func testPercentageSplit() {
        let a = Participant(name: "A")
        let b = Participant(name: "B")
        let splits = BalanceEngine.computeSplits(
            amount: 100,
            participants: [a, b],
            mode: .percentages([a.id: 75, b.id: 25])
        )
        XCTAssertEqual(splits.map(\.amount).reduce(0, +), 100)
        XCTAssertEqual(splits.first { $0.participantId == a.id }?.amount, 75)
        XCTAssertEqual(splits.first { $0.participantId == b.id }?.amount, 25)
    }

    func testPercentageSplitRoundingPutsRemainderOnLast() {
        let a = Participant(name: "A")
        let b = Participant(name: "B")
        let c = Participant(name: "C")
        // 100 / 3 each ≈ 33.33% of total when using equal percentages
        let splits = BalanceEngine.computeSplits(
            amount: 100,
            participants: [a, b, c],
            mode: .percentages([a.id: 1, b.id: 1, c.id: 1])
        )
        XCTAssertEqual(splits.map(\.amount).reduce(0, +), 100)
        let amounts = Dictionary(uniqueKeysWithValues: splits.map { ($0.participantId, $0.amount) })
        // First two get rounded shares; last absorbs remainder so total is exact
        XCTAssertEqual(amounts.values.reduce(0, +), 100)
    }

    func testTwoPersonEqualExpenseBalances() {
        let you = Participant(name: "You", isCurrentUser: true)
        let friend = Participant(name: "Friend")
        let tripId = UUID()
        let trip = Trip(
            id: tripId,
            name: "Dinner",
            startDate: Date(),
            endDate: Date(),
            participants: [you, friend],
            expenses: [makeEqualExpense(tripId: tripId, amount: 80, payer: you, participants: [you, friend])]
        )
        let ledger = BalanceEngine.computeLedger(for: trip)
        XCTAssertEqual(ledger.first { $0.participantId == you.id }?.balance, 40)
        XCTAssertEqual(ledger.first { $0.participantId == friend.id }?.balance, -40)

        let debts = BalanceEngine.computeSimplifiedDebts(ledger: ledger)
        XCTAssertEqual(debts.count, 1)
        XCTAssertEqual(debts[0].fromParticipantId, friend.id)
        XCTAssertEqual(debts[0].toParticipantId, you.id)
        XCTAssertEqual(debts[0].amount, 40)
    }

    func testExcludeOnePersonFromSplit() {
        let a = Participant(name: "A", isCurrentUser: true)
        let b = Participant(name: "B")
        let c = Participant(name: "C")
        let tripId = UUID()
        // A paid 90, only B and C split (A excluded) → each of B,C owes 45; A is owed 90
        let splits = BalanceEngine.computeSplits(amount: 90, participants: [b, c], mode: .equal)
        let expense = Expense(
            tripId: tripId,
            amount: 90,
            paidByParticipantId: a.id,
            splits: splits
        )
        let trip = Trip(
            id: tripId,
            name: "Taxi",
            startDate: Date(),
            endDate: Date(),
            participants: [a, b, c],
            expenses: [expense]
        )
        let ledger = BalanceEngine.computeLedger(for: trip)
        XCTAssertEqual(ledger.first { $0.participantId == a.id }?.balance, 90)
        XCTAssertEqual(ledger.first { $0.participantId == b.id }?.balance, -45)
        XCTAssertEqual(ledger.first { $0.participantId == c.id }?.balance, -45)
    }

    func testPartialSettlementLeavesRemainder() {
        let divya = Participant(name: "Divya", isCurrentUser: true)
        let gabe = Participant(name: "Gabe")
        let tripId = UUID()
        let trip = Trip(
            id: tripId,
            name: "Partial",
            startDate: Date(),
            endDate: Date(),
            participants: [divya, gabe],
            expenses: [makeEqualExpense(tripId: tripId, amount: 100, payer: divya, participants: [divya, gabe])],
            settlements: [Settlement(tripId: tripId, fromParticipantId: gabe.id, toParticipantId: divya.id, amount: 20)]
        )
        let ledger = BalanceEngine.computeLedger(for: trip)
        XCTAssertEqual(ledger.first { $0.participantId == gabe.id }?.balance, -30)
        XCTAssertEqual(ledger.first { $0.participantId == divya.id }?.balance, 30)
        let debts = BalanceEngine.computeSimplifiedDebts(ledger: ledger)
        XCTAssertEqual(debts.count, 1)
        XCTAssertEqual(debts[0].amount, 30)
    }

    // MARK: - Settlements

    func testSettlementReducesBalances() {
        let divya = Participant(name: "Divya", isCurrentUser: true)
        let gabe = Participant(name: "Gabe")
        var trip = Trip(
            name: "Test",
            startDate: Date(),
            endDate: Date(),
            participants: [divya, gabe],
            expenses: [makeEqualExpense(tripId: UUID(), amount: 100, payer: divya, participants: [divya, gabe])]
        )

        var ledger = BalanceEngine.computeLedger(for: trip)
        XCTAssertEqual(ledger.first { $0.participantId == gabe.id }?.balance, -50)

        trip.settlements = [
            Settlement(tripId: trip.id, fromParticipantId: gabe.id, toParticipantId: divya.id, amount: 50)
        ]
        ledger = BalanceEngine.computeLedger(for: trip)
        XCTAssertEqual(ledger.first { $0.participantId == gabe.id }?.balance, 0)
        XCTAssertEqual(ledger.first { $0.participantId == divya.id }?.balance, 0)
    }

    func testFullySettledTripHasNoDebts() {
        let divya = Participant(name: "Divya", isCurrentUser: true)
        let gabe = Participant(name: "Gabe")
        let tripId = UUID()
        let trip = Trip(
            id: tripId,
            name: "Settled",
            startDate: Date(),
            endDate: Date(),
            participants: [divya, gabe],
            expenses: [makeEqualExpense(tripId: tripId, amount: 40, payer: divya, participants: [divya, gabe])],
            settlements: [Settlement(tripId: tripId, fromParticipantId: gabe.id, toParticipantId: divya.id, amount: 20)]
        )

        let summary = BalanceEngine.computeSummary(for: trip)
        XCTAssertTrue(summary.isFullySettled)
    }

    // MARK: - Helpers

    private func makeEqualExpense(
        tripId: UUID,
        amount: Decimal,
        payer: Participant,
        participants: [Participant]
    ) -> Expense {
        let splits = BalanceEngine.computeSplits(amount: amount, participants: participants, mode: .equal)
        return Expense(
            tripId: tripId,
            amount: amount,
            paidByParticipantId: payer.id,
            splits: splits
        )
    }
}
