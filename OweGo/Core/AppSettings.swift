import Foundation
import UIKit

enum AppSettings {
    private enum Keys {
        static let currentUserName = "currentUserName"
        static let venmoHandle = "venmoHandle"
    }

    static var currentUserName: String {
        get {
            let stored = UserDefaults.standard.string(forKey: Keys.currentUserName) ?? ""
            // Migrate old default placeholder
            if stored.caseInsensitiveCompare("You") == .orderedSame { return "" }
            return stored
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            UserDefaults.standard.set(trimmed, forKey: Keys.currentUserName)
        }
    }

    static var venmoHandle: String {
        get { UserDefaults.standard.string(forKey: Keys.venmoHandle) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.venmoHandle) }
    }

    static var hasConfiguredName: Bool {
        let name = currentUserName
        return !name.isEmpty && name.caseInsensitiveCompare("You") != .orderedSame
    }

    static var hasVenmoHandle: Bool {
        !normalizedVenmoHandle(venmoHandle).isEmpty
    }

    static func normalizedVenmoHandle(_ raw: String = venmoHandle) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }
}

extension Participant {
    /// Name suitable for UI and shared reports — never the placeholder "You".
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.caseInsensitiveCompare("You") == .orderedSame {
            let fromSettings = AppSettings.currentUserName
            if AppSettings.hasConfiguredName {
                return fromSettings
            }
        }
        return trimmed.isEmpty ? "Someone" : trimmed
    }
}

enum VenmoTxn: String {
    case pay
    case charge
}

enum VenmoLinkBuilder {
    static func profileURL(handle: String) -> URL? {
        let trimmed = AppSettings.normalizedVenmoHandle(handle)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: "https://venmo.com/u/\(trimmed)")
    }

    /// Native app scheme — prefer when Venmo is installed.
    static func appPaymentURL(
        recipientHandle: String,
        amount: Decimal,
        note: String,
        txn: VenmoTxn = .pay
    ) -> URL? {
        let trimmed = AppSettings.normalizedVenmoHandle(recipientHandle)
        guard !trimmed.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = "venmo"
        components.host = "paycharge"
        components.queryItems = [
            URLQueryItem(name: "txn", value: txn.rawValue),
            URLQueryItem(name: "recipients", value: trimmed),
            URLQueryItem(name: "amount", value: formattedAmount(amount)),
            URLQueryItem(name: "note", value: sanitizeNote(note))
        ]
        return components.url
    }

    /// HTTPS pay link — better for Messages / when app scheme drops recipient.
    static func webPaymentURL(
        recipientHandle: String,
        amount: Decimal,
        note: String,
        txn: VenmoTxn = .pay
    ) -> URL? {
        let trimmed = AppSettings.normalizedVenmoHandle(recipientHandle)
        guard !trimmed.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "account.venmo.com"
        components.path = "/pay"
        components.queryItems = [
            URLQueryItem(name: "txn", value: txn.rawValue),
            URLQueryItem(name: "audience", value: "private"),
            URLQueryItem(name: "amount", value: formattedAmount(amount)),
            URLQueryItem(name: "note", value: sanitizeNote(note)),
            // Leading comma is required by the post-breakage web format.
            URLQueryItem(name: "recipients", value: ",\(trimmed)")
        ]
        return components.url
    }

    /// Legacy alias → app payment URL with `pay`.
    static func paymentURL(
        recipientHandle: String,
        amount: Decimal,
        note: String
    ) -> URL? {
        appPaymentURL(recipientHandle: recipientHandle, amount: amount, note: note, txn: .pay)
    }

    /// Same `venmo://` pay URL used by in-app Open pay link (reports, copy request, Messages).
    static func shareablePayURL(
        recipientHandle: String = AppSettings.venmoHandle,
        amount: Decimal,
        note: String
    ) -> URL? {
        appPaymentURL(recipientHandle: recipientHandle, amount: amount, note: note, txn: .pay)
    }

    /// Always attempts `venmo://` first (does not gate on canOpenURL), then HTTPS, then profile.
    @MainActor
    static func openPayment(
        recipientHandle: String,
        amount: Decimal,
        note: String,
        txn: VenmoTxn = .pay
    ) {
        let cleanNote = sanitizeNote(note)
        let appURL = appPaymentURL(
            recipientHandle: recipientHandle,
            amount: amount,
            note: cleanNote,
            txn: txn
        )
        let webURL = webPaymentURL(
            recipientHandle: recipientHandle,
            amount: amount,
            note: cleanNote,
            txn: txn
        )
        let profile = profileURL(handle: recipientHandle)

        if let appURL {
            UIApplication.shared.open(appURL, options: [:]) { success in
                if success { return }
                if let webURL {
                    UIApplication.shared.open(webURL, options: [:]) { webSuccess in
                        if !webSuccess, let profile {
                            UIApplication.shared.open(profile)
                        }
                    }
                } else if let profile {
                    UIApplication.shared.open(profile)
                }
            }
            return
        }

        if let webURL {
            UIApplication.shared.open(webURL, options: [:]) { success in
                if !success, let profile {
                    UIApplication.shared.open(profile)
                }
            }
            return
        }

        if let profile {
            UIApplication.shared.open(profile)
        }
    }

    private static func sanitizeNote(_ note: String) -> String {
        note
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func formattedAmount(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter.string(from: number) ?? String(format: "%.2f", number.doubleValue)
    }
}

enum PaymentRequestBuilder {
    static func message(
        debtorName: String,
        creditorName: String,
        amount: Decimal,
        tripName: String,
        venmoPayURL: URL? = nil
    ) -> String {
        var text = "Hey \(debtorName), you owe \(creditorName) \(CurrencyFormatter.string(from: amount)) for \(tripName)."
        if let venmoPayURL {
            text += "\n\nPay on Venmo:\n\(venmoPayURL.absoluteString)"
        }
        return text
    }
}
