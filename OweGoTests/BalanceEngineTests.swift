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
