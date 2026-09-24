import Foundation

enum TripReportBuilder {
    static func groupReport(
        trip: Trip,
        summary: TripBalanceSummary,
        venmoHandle: String = AppSettings.venmoHandle
    ) -> String {
        var lines: [String] = []

        let crew = trip.participants.map(\.displayName)
        let greeting: String = {
            switch crew.count {
            case 0:
                return "Hey crew,"
            case 1:
                return "Hi \(crew[0]),"
            case 2:
                return "Hi \(crew[0]) and \(crew[1]),"
            default:
                let listed = crew.dropLast().joined(separator: ", ")
                return "Hi \(listed), and \(crew.last!),"
            }
        }()

        lines.append(greeting)
        lines.append("")
        lines.append("That’s a wrap on \(trip.name). Here’s the trip tab so nobody has to dig through the chat.")
        lines.append(DateFormatterHelper.tripDateRange(start: trip.startDate, end: trip.endDate))

        let participantCount = max(trip.participants.count, 1)
        let perPerson = summary.totalSpent / Decimal(participantCount)
        lines.append(
            "\(CurrencyFormatter.string(from: summary.totalSpent)) total · ~\(CurrencyFormatter.string(from: perPerson)) each · \(summary.expenseCount) moments"
        )
        lines.append("")

        if summary.simplifiedDebts.isEmpty {
            lines.append("You’re all settled. Nothing left to chase. Go make more memories.")
            lines.append("")
        } else {
            let count = summary.simplifiedDebts.count
            lines.append(
                count == 1
                    ? "One easy settle-up left:"
                    : "A few easy settle-ups (\(count)):"
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
                "Big props to \(name) for fronting the most (\(CurrencyFormatter.string(from: fronter.paid)))."
            )
            lines.append("")
        }

        let expenses = TripStoryHelpers.allExpenses(on: trip)
        if !expenses.isEmpty {
            lines.append("Here’s what went on the trip tab:")
            for moment in expenses {
                lines.append(
                    "• \(moment.title) - \(CurrencyFormatter.string(from: moment.amount)) (\(moment.payerName) paid)"
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

        lines.append("Less owing. More going.")

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
        let firstName = name.split(separator: " ").first.map(String.init) ?? name
        let ledger = summary.ledgers.first(where: { $0.participantId == participant.id })
        let balance = ledger?.balance ?? 0

        lines.append("Hi \(firstName),")
        lines.append("")

        if balance > 0 {
            lines.append("Quick wrap-up for \(trip.name). You’re owed a little something.")
        } else if balance < 0 {
            lines.append("Quick wrap-up for \(trip.name). Here’s your piece of the trip tab.")
        } else {
            lines.append("Quick wrap-up for \(trip.name). You’re all settled.")
        }
        lines.append(DateFormatterHelper.tripDateRange(start: trip.startDate, end: trip.endDate))
        lines.append("")

        if balance > 0 {
            lines.append("Nice one. You’re owed \(CurrencyFormatter.string(from: balance)).")
        } else if balance < 0 {
            lines.append("Your share comes to \(CurrencyFormatter.string(from: -balance)) when you get a chance.")
        } else {
            lines.append("Nothing left to chase. Go make more memories.")
        }
        lines.append("")

        let myDebts = summary.simplifiedDebts.filter {
            $0.fromParticipantId == participant.id || $0.toParticipantId == participant.id
        }
        if !myDebts.isEmpty {
            lines.append(myDebts.count == 1 ? "Your settle-up:" : "Your settle-ups:")
            for debt in myDebts {
                if debt.fromParticipantId == participant.id {
                    lines.append(
                        "• You → \(debt.toName)  \(CurrencyFormatter.string(from: debt.amount))"
                    )
                } else {
                    lines.append(
                        "• \(debt.fromName) → you  \(CurrencyFormatter.string(from: debt.amount))"
                    )
                }
            }
            lines.append("")
        }

        let moments = TripStoryHelpers.expenses(involving: participant.id, on: trip)
        if !moments.isEmpty {
            lines.append("What you were on:")
            for moment in moments {
                lines.append(
                    "• \(moment.title) - your share \(CurrencyFormatter.string(from: moment.relevantAmount)) (of \(CurrencyFormatter.string(from: moment.amount)), \(moment.payerName) paid)"
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
                intro: "Pay in a tap on Venmo when you’re ready:"
            )
        }

        lines.append("Less owing. More going.")

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
            intro: "Pay in a tap on Venmo:"
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
