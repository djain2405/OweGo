import Foundation

enum CurrencyFormatter {
    static func string(from amount: Decimal) -> String {
        let number = amount as NSDecimalNumber
        return formatter.string(from: number) ?? "$\(number)"
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()
}

enum DateFormatterHelper {
    static func tripDateRange(start: Date, end: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(start, equalTo: end, toGranularity: .day) {
            return mediumDate.string(from: start)
        }
        if calendar.isDate(start, equalTo: end, toGranularity: .year) {
            return "\(shortDate.string(from: start)) – \(shortDate.string(from: end)), \(year.string(from: end))"
        }
        return "\(mediumDate.string(from: start)) – \(mediumDate.string(from: end))"
    }

    static func relativeDay(_ date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// Whole days from today to `date` (negative if in the past).
    static func daysFromToday(to date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func countdownPhrase(until start: Date) -> String {
        let days = daysFromToday(to: start)
        if days == 0 { return "Starts today" }
        if days == 1 { return "Starts tomorrow" }
        if days > 1 { return "in \(days) days" }
        return tripDateRange(start: start, end: start)
    }

    static func shortMonthDay(_ date: Date) -> String {
        shortDate.string(from: date)
    }

    private static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()

    private static let year: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yyyy")
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}
