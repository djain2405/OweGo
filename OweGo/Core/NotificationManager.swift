import Foundation
import UserNotifications

enum NotificationManager {
    static func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func scheduleTripNotifications(for trip: Trip, summary: TripBalanceSummary) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: notificationIDs(for: trip.id))

        guard !trip.isEnded else { return }

        if let currentUser = trip.currentUser,
           let ledger = summary.ledgers.first(where: { $0.participantId == currentUser.id }),
           ledger.balance < 0 {
            schedule(
                id: "owe-\(trip.id.uuidString)",
                title: "Balance update",
                body: "You currently owe \(CurrencyFormatter.string(from: abs(ledger.balance))) on \(trip.name).",
                date: nextMorning()
            )
        }

        let calendar = Calendar.current
        if let dayBeforeEnd = calendar.date(byAdding: .day, value: -1, to: trip.endDate) {
            let outstanding = summary.remainingDebtCount
            schedule(
                id: "ending-\(trip.id.uuidString)",
                title: "Trip ending tomorrow",
                body: "\(trip.name) ends tomorrow — \(trip.expenses.count) expenses logged, \(outstanding) balances remaining.",
                date: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dayBeforeEnd) ?? dayBeforeEnd
            )
        }
    }

    private static func notificationIDs(for tripId: UUID) -> [String] {
        ["owe-\(tripId.uuidString)", "ending-\(tripId.uuidString)"]
    }

    private static func schedule(id: String, title: String, body: String, date: Date) {
        guard date > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static func nextMorning() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}
