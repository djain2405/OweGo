import Foundation

enum TripReportBuilder {
    static func groupReport(
        trip: Trip,
        summary: TripBalanceSummary,
        venmoHandle: String = AppSettings.venmoHandle
    ) -> String {
        var lines: [String] = []

        lines.append("\(trip.name) is wrapped")
        lines.append(DateFormatterHelper.tripDateRange(start: trip.startDate, end: trip.endDate))

        let participantCount = max(trip.participants.count, 1)
        let perPerson = summary.totalSpent / Decimal(participantCount)
        lines.append(
            "\(CurrencyFormatter.string(from: summary.totalSpent)) spent · ~\(CurrencyFormatter.string(from: perPerson)) each · \(summary.expenseCount) expenses"
        )
        lines.append("")

        if summary.simplifiedDebts.isEmpty {
            lines.append("Everyone is square. Nothing left to settle.")
            lines.append("")
        } else {
            let count = summary.simplifiedDebts.count
            lines.append(
                count == 1
                    ? "1 settlement left. Here’s who pays whom:"
                    : "\(count) settlements left. Here’s who pays whom:"
            )
            for (index, debt) in summary.simplifiedDebts.enumerated() {
                lines.append(
                    "\(index + 1). \(debt.fromName) → \(debt.toName)  \(CurrencyFormatter.string(from: debt.amount))"
                )
            }
            lines.append("")
        }

        if let fronter = TripStoryHelpers.whoFrontedMost(summary: summary) {
            let name = resolvedLedgerName(fronter, trip: trip)
            lines.append(
                "\(name) fronted the most (\(CurrencyFormatter.string(from: fronter.paid)))."
            )
            lines.append("")
        }

        let why = TripStoryHelpers.topExpenses(on: trip, limit: 5)
        if !why.isEmpty {
            lines.append("Why it adds up")
            for moment in why {
                lines.append(
                    "• \(moment.title) — \(CurrencyFormatter.string(from: moment.amount)) (\(moment.payerName))"
                )
            }
            lines.append("")
        }

        appendOrganizerPayLinks(
            to: &lines,
            trip: trip,
            debts: summary.simplifiedDebts,
            venmoHandle: venmoHandle
        )

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func memberReport(
        trip: Trip,
        summary: TripBalanceSummary,
        participant: Participant,
        venmoHandle: String = AppSettings.venmoHandle
    ) -> String {
        var lines: [String] = []
        let name = participant.displayName
        let ledger = summary.ledgers.first(where: { $0.participantId == participant.id })
        let balance = ledger?.balance ?? 0

        if balance > 0 {
            lines.append("\(name) — you’re owed for \(trip.name)")
        } else if balance < 0 {
            lines.append("\(name) — your \(trip.name) bill")
        } else {
            lines.append("\(name) — \(trip.name) (all settled)")
        }
        lines.append(DateFormatterHelper.tripDateRange(start: trip.startDate, end: trip.endDate))
        lines.append("")

        if balance > 0 {
            lines.append("\(name) is owed \(CurrencyFormatter.string(from: balance)).")
        } else if balance < 0 {
            lines.append("\(name) owes \(CurrencyFormatter.string(from: -balance)) overall.")
        } else {
            lines.append("\(name) is all settled for this trip.")
        }
        lines.append("")

        let myDebts = summary.simplifiedDebts.filter {
            $0.fromParticipantId == participant.id || $0.toParticipantId == participant.id
        }
        if !myDebts.isEmpty {
            lines.append("Settlements")
            for debt in myDebts {
                if debt.fromParticipantId == participant.id {
                    lines.append(
                        "• \(name) → \(debt.toName)  \(CurrencyFormatter.string(from: debt.amount))"
                    )
                } else {
                    lines.append(
                        "• \(debt.fromName) → \(name)  \(CurrencyFormatter.string(from: debt.amount))"
                    )
                }
            }
            lines.append("")
        }

        let why = TripStoryHelpers.topExpenses(involving: participant.id, on: trip, limit: 8)
        if !why.isEmpty {
            lines.append("Here’s why")
            for moment in why {
                lines.append(
                    "• \(moment.title) — \(name)’s share \(CurrencyFormatter.string(from: moment.relevantAmount)) (of \(CurrencyFormatter.string(from: moment.amount)), \(moment.payerName) paid)"
                )
            }
            lines.append("")
        }

        // Pay links when this person owes the organizer (Settings Venmo = organizer).
        if let organizer = trip.currentUser {
            let owingOrganizer = myDebts.filter {
                $0.fromParticipantId == participant.id && $0.toParticipantId == organizer.id
            }
            appendPayLinks(
                to: &lines,
                debts: owingOrganizer,
                tripName: trip.name,
                venmoHandle: venmoHandle,
                intro: "Tap to pay on Venmo"
            )
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func report(
        trip: Trip,
        summary: TripBalanceSummary,
        venmoHandle: String = AppSettings.venmoHandle
    ) -> String {
        groupReport(trip: trip, summary: summary, venmoHandle: venmoHandle)
    }

    // MARK: - Private

    private static func appendOrganizerPayLinks(
        to lines: inout [String],
        trip: Trip,
        debts: [SimplifiedDebt],
        venmoHandle: String
    ) {
        guard let organizer = trip.currentUser else { return }
        let owedToOrganizer = debts.filter { $0.toParticipantId == organizer.id }
        appendPayLinks(
            to: &lines,
            debts: owedToOrganizer,
            tripName: trip.name,
            venmoHandle: venmoHandle,
            intro: "Tap to pay on Venmo"
        )
    }

    private static func appendPayLinks(
        to lines: inout [String],
        debts: [SimplifiedDebt],
        tripName: String,
        venmoHandle: String,
        intro: String
    ) {
        let trimmed = AppSettings.normalizedVenmoHandle(venmoHandle)
        guard !trimmed.isEmpty, !debts.isEmpty else { return }

        lines.append(intro)
        for debt in debts {
            let note = "\(tripName) - \(debt.fromName)"
            if let url = VenmoLinkBuilder.shareablePayURL(
                recipientHandle: trimmed,
                amount: debt.amount,
                note: note
            ) {
                lines.append(
                    "\(debt.fromName) → \(debt.toName) \(CurrencyFormatter.string(from: debt.amount))"
                )
                lines.append(url.absoluteString)
            }
        }
        lines.append("")
    }

    private static func resolvedLedgerName(_ ledger: ParticipantLedger, trip: Trip) -> String {
        if let participant = trip.participants.first(where: { $0.id == ledger.participantId }) {
            return participant.displayName
        }
        let trimmed = ledger.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.caseInsensitiveCompare("You") == .orderedSame, AppSettings.hasConfiguredName {
            return AppSettings.currentUserName
        }
        return trimmed.isEmpty ? "Someone" : trimmed
    }
}
