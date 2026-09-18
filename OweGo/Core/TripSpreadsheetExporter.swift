import Foundation

enum TripSpreadsheetExporter {
    /// Writes a UTF-8 BOM CSV (Excel-friendly) to a temp file and returns its URL.
    static func exportCSV(trip: Trip, summary: TripBalanceSummary) throws -> URL {
        let content = buildCSV(trip: trip, summary: summary)
        let safeName = sanitizeFilename(trip.name)
        let filename = "\(safeName)-owego.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        var data = Data([0xEF, 0xBB, 0xBF]) // UTF-8 BOM for Excel
        guard let body = content.data(using: .utf8) else {
            throw ExporterError.encodingFailed
        }
        data.append(body)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func buildCSV(trip: Trip, summary: TripBalanceSummary) -> String {
        var rows: [String] = []

        rows.append(csvRow(["Expenses"]))
        rows.append(csvRow([
            "Date", "Description", "Category", "Amount", "Paid By", "Split With", "Notes"
        ]))

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let expenses = trip.expenses.sorted { $0.createdAt < $1.createdAt }
        for expense in expenses {
            let payer = trip.participants.first(where: { $0.id == expense.paidByParticipantId })?.displayName ?? ""
            let splitNames = expense.splits.compactMap { split in
                trip.participants.first(where: { $0.id == split.participantId })?.displayName
            }.joined(separator: "; ")
            let title = expense.description.isEmpty ? expense.category.rawValue : expense.description
            rows.append(csvRow([
                dateFormatter.string(from: expense.createdAt),
                title,
                expense.category.rawValue,
                plainAmount(expense.amount),
                payer,
                splitNames,
                expense.notes ?? ""
            ]))
        }

        rows.append("")
        rows.append(csvRow(["Balances"]))
        rows.append(csvRow(["Person", "Paid", "Share", "Balance"]))
        for ledger in summary.ledgers {
            let personName: String = {
                if let p = trip.participants.first(where: { $0.id == ledger.participantId }) {
                    return p.displayName
                }
                return ledger.name
            }()
            rows.append(csvRow([
                personName,
                plainAmount(ledger.paid),
                plainAmount(ledger.share),
                plainAmount(ledger.balance)
            ]))
        }

        return rows.joined(separator: "\n")
    }

    // MARK: - Private

    private enum ExporterError: LocalizedError {
        case encodingFailed

        var errorDescription: String? {
            "Couldn't encode spreadsheet data."
        }
    }

    private static func csvRow(_ fields: [String]) -> String {
        fields.map(escape).joined(separator: ",")
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }

    private static func plainAmount(_ amount: Decimal) -> String {
        NSDecimalNumber(decimal: amount).stringValue
    }

    private static func sanitizeFilename(_ name: String) -> String {
        let cleaned = name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "trip" : cleaned
    }
}
