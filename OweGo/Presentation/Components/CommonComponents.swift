import SwiftUI

// MARK: - Avatars

struct ParticipantAvatar: View {
    let name: String
    var size: CGFloat = 36

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(backgroundColor.gradient)
            .clipShape(Circle())
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var backgroundColor: Color {
        let colors: [Color] = [
            OweGoTheme.primary,
            OweGoTheme.secondary,
            Color(red: 0.45, green: 0.55, blue: 0.85),
            Color(red: 0.65, green: 0.45, blue: 0.75),
            Color(red: 0.35, green: 0.65, blue: 0.55)
        ]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
}

struct ParticipantAvatarRow: View {
    let participants: [Participant]
    var maxVisible: Int = 5

    var body: some View {
        HStack(spacing: -8) {
            ForEach(participants.prefix(maxVisible)) { participant in
                ParticipantAvatar(name: participant.name, size: 32)
                    .overlay(Circle().stroke(OweGoTheme.card, lineWidth: 2))
            }
            if participants.count > maxVisible {
                Text("+\(participants.count - maxVisible)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(OweGoTheme.primary)
                    .frame(width: 32, height: 32)
                    .background(OweGoTheme.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(OweGoTheme.card, lineWidth: 2))
            }
        }
    }
}

// MARK: - Buttons

struct OweGoPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(OweGoTheme.primary.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct OweGoSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(OweGoTheme.primary)
            .background(OweGoTheme.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct OweGoFAB: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title).fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(OweGoTheme.primary.gradient)
            .clipShape(Capsule())
            .shadow(color: OweGoTheme.primary.opacity(0.35), radius: 12, x: 0, y: 6)
        }
    }
}

// MARK: - Trip Cards

struct TripHeroCard: View {
    let trip: Trip
    @State private var appeared = false

    private var summary: TripBalanceSummary {
        BalanceEngine.computeSummary(for: trip)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                ActiveTripDot()
                Text("Live now")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.95))
                Spacer()
                TripStatusBadge(trip: trip, lightStyle: true)
            }

            Text(trip.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(DateFormatterHelper.tripDateRange(start: trip.startDate, end: trip.endDate))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.88))

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total spent")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(CurrencyFormatter.string(from: trip.totalSpent))
                        .font(OweGoTheme.moneyFont(size: 26))
                        .foregroundStyle(.white)
                    if summary.remainingDebtCount > 0 {
                        Text(
                            summary.remainingDebtCount == 1
                                ? "1 left to settle"
                                : "\(summary.remainingDebtCount) left to settle"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.top, 2)
                    } else if !trip.expenses.isEmpty {
                        Text("All settled")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.top, 2)
                    }
                }
                Spacer()
                ParticipantAvatarRow(participants: trip.participants)
            }
        }
        .padding(22)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .topTrailing) {
                OweGoTheme.heroGradient
                OweGoTheme.heroOverlay
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 88, weight: .light))
                    .foregroundStyle(.white.opacity(0.12))
                    .offset(x: 18, y: -8)
                    .rotationEffect(.degrees(8))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: OweGoTheme.cardRadius + 2, style: .continuous))
        .shadow(color: OweGoTheme.primary.opacity(0.32), radius: 16, x: 0, y: 8)
        .scaleEffect(appeared ? 1 : 0.97)
        .opacity(appeared ? 1 : 0.7)
        .onAppear {
            withAnimation(OweGoTheme.spring) { appeared = true }
        }
    }
}

struct TripUpcomingCard: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 0) {
            OweGoTheme.primary
                .frame(width: 5)

            HStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text(DateFormatterHelper.shortMonthDay(trip.startDate).uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(OweGoTheme.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 52)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 6)
                .background(OweGoTheme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(trip.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(OweGoTheme.textPrimary)
                    Text(DateFormatterHelper.countdownPhrase(until: trip.startDate))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(OweGoTheme.primary)
                    HStack(spacing: 10) {
                        ParticipantAvatarRow(participants: trip.participants, maxVisible: 4)
                        Text("\(trip.participants.count)")
                            .font(.caption)
                            .foregroundStyle(OweGoTheme.textSecondary)
                    }
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(OweGoTheme.textSecondary)
            }
            .padding(14)
        }
        .owegoUpcomingCard()
    }
}

struct TripPastCard: View {
    let trip: Trip

    private var summary: TripBalanceSummary {
        BalanceEngine.computeSummary(for: trip)
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(trip.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OweGoTheme.textPrimary.opacity(0.85))
                    Spacer()
                    pastStatusChip
                }
                Text(DateFormatterHelper.tripDateRange(start: trip.startDate, end: trip.endDate))
                    .font(.caption)
                    .foregroundStyle(OweGoTheme.textSecondary)
                Text(CurrencyFormatter.string(from: trip.totalSpent) + " total")
                    .font(.caption)
                    .foregroundStyle(OweGoTheme.textSecondary.opacity(0.9))
            }
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(OweGoTheme.textSecondary.opacity(0.7))
        }
        .padding(14)
        .owegoPastCard()
    }

    private var pastStatusChip: some View {
        let settled = summary.isFullySettled
        return Text(settled ? "Settled" : "Open balances")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(settled ? OweGoTheme.positive : OweGoTheme.negative)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background((settled ? OweGoTheme.positive : OweGoTheme.negative).opacity(0.12))
            .clipShape(Capsule())
    }
}

/// Legacy alias — prefer TripUpcomingCard / TripPastCard.
struct TripCompactCard: View {
    let trip: Trip

    var body: some View {
        if trip.isPast || trip.isEnded {
            TripPastCard(trip: trip)
        } else {
            TripUpcomingCard(trip: trip)
        }
    }
}

struct ActiveTripDot: View {
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
            .scaleEffect(pulsing ? 1.3 : 1.0)
            .opacity(pulsing ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulsing)
            .onAppear { pulsing = true }
    }
}

// MARK: - Balance

struct BalanceHero: View {
    let userName: String
    let balance: Decimal
    let paid: Decimal
    let totalSpent: Decimal
    var onSettle: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(statusSentence)
                .font(.title3.weight(.semibold))
                .foregroundStyle(OweGoTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if paid > 0, totalSpent > 0 {
                Text("\(userName) fronted \(CurrencyFormatter.string(from: paid)) of \(CurrencyFormatter.string(from: totalSpent)) group spend")
                    .font(.subheadline)
                    .foregroundStyle(OweGoTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let onSettle {
                Button(action: onSettle) {
                    Text("Settle up")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(OweGoTheme.primary)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background {
            ZStack {
                OweGoTheme.card
                OweGoTheme.softHeroWash
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: OweGoTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: OweGoTheme.cardRadius, style: .continuous)
                .stroke(OweGoTheme.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: OweGoTheme.primary.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    private var statusSentence: String {
        let amount = CurrencyFormatter.string(from: abs(balance))
        if balance > 0 {
            return "\(userName), you’re owed \(amount)"
        }
        if balance < 0 {
            return "\(userName), you owe \(amount) overall"
        }
        return "\(userName), you’re all even"
    }
}

struct StatChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(OweGoTheme.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OweGoTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(OweGoTheme.cardMuted)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct PersonBalanceCard: View {
    let otherName: String
    let selfName: String
    let amount: Decimal
    let isOwedToYou: Bool
    var reason: String?

    var body: some View {
        HStack(spacing: 12) {
            ParticipantAvatar(name: otherName)
            VStack(alignment: .leading, spacing: 4) {
                Text(sentence)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(OweGoTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                if let reason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(OweGoTheme.textSecondary)
                }
            }
            Spacer(minLength: 8)
            Text(CurrencyFormatter.string(from: amount))
                .font(.headline.weight(.bold))
                .foregroundStyle(isOwedToYou ? OweGoTheme.positive : OweGoTheme.negative)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(OweGoTheme.textSecondary)
        }
        .padding(14)
        .owegoCard()
    }

    private var sentence: String {
        isOwedToYou ? "\(otherName) owes \(selfName)" : "\(selfName) owes \(otherName)"
    }
}

/// Peer-to-peer debt (neither person is the current user) — view only, quieter style.
struct PeerDebtCard: View {
    let fromName: String
    let toName: String
    let amount: Decimal
    var reason: String?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(fromName) owes \(toName)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(OweGoTheme.textSecondary)
                if let reason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(OweGoTheme.textSecondary.opacity(0.85))
                }
            }
            Spacer()
            Text(CurrencyFormatter.string(from: amount))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OweGoTheme.textSecondary)
        }
        .padding(14)
        .background(OweGoTheme.cardMuted)
        .clipShape(RoundedRectangle(cornerRadius: OweGoTheme.cardRadius, style: .continuous))
    }
}

struct BalanceRow: View {
    let name: String
    let amount: Decimal
    let isCurrentUserPerspective: Bool

    var body: some View {
        PersonBalanceCard(
            otherName: name,
            selfName: AppSettings.hasConfiguredName ? AppSettings.currentUserName : "you",
            amount: amount,
            isOwedToYou: isCurrentUserPerspective
        )
    }
}

// MARK: - Expense

struct ExpenseCard: View {
    let expense: Expense
    let payerName: String

    var body: some View {
        HStack(spacing: 0) {
            categoryColor
                .frame(width: 5)
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: expense.category.icon)
                    .font(.title3)
                    .foregroundStyle(categoryColor)
                    .frame(width: 36, height: 36)
                    .background(categoryColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.description.isEmpty ? expense.category.rawValue : expense.description)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(OweGoTheme.textPrimary)
                    Text("\(payerName) paid · \(DateFormatterHelper.relativeDay(expense.createdAt))")
                        .font(.subheadline)
                        .foregroundStyle(OweGoTheme.textSecondary)
                }
                Spacer(minLength: 8)
                Text(CurrencyFormatter.string(from: expense.amount))
                    .font(.body.weight(.bold))
                    .foregroundStyle(OweGoTheme.textPrimary)
            }
            .padding(14)
        }
        .owegoCard()
    }

    private var categoryColor: Color {
        switch expense.category {
        case .food: return OweGoTheme.secondary
        case .transport: return OweGoTheme.primary
        case .lodging: return Color(red: 0.45, green: 0.55, blue: 0.85)
        case .activities: return OweGoTheme.positive
        case .supplies: return Color(red: 0.65, green: 0.45, blue: 0.75)
        case .other: return .gray
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    let payerName: String

    var body: some View {
        ExpenseCard(expense: expense, payerName: payerName)
    }
}

// MARK: - Misc

struct StatCard: View {
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        StatChip(title: title, value: value)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?
    /// When set, shows the brand logo instead of the SF Symbol badge.
    var logoAssetName: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Image(systemName: "map.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(OweGoTheme.primary.opacity(0.06))
                    .offset(x: 40, y: -20)
                if let logoAssetName {
                    Image(logoAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 112, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: OweGoTheme.cardShadow, radius: 12, y: 6)
                } else {
                    Circle()
                        .fill(OweGoTheme.primary.opacity(0.12))
                        .frame(width: 110, height: 110)
                    Image(systemName: systemImage)
                        .font(.system(size: 42))
                        .foregroundStyle(OweGoTheme.primary)
                }
            }
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(OweGoTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(OweGoTheme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                OweGoPrimaryButton(actionTitle, icon: "plus", action: action)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }
        }
        .padding(32)
    }
}

struct TripStatusBadge: View {
    let trip: Trip
    var lightStyle: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if !lightStyle {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            }
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(lightStyle ? .white.opacity(0.95) : color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(lightStyle ? Color.white.opacity(0.2) : color.opacity(0.12))
        .clipShape(Capsule())
    }

    private var label: String {
        if trip.isEnded { return "Ended" }
        if trip.isActive { return "Active" }
        if trip.isPast { return "Past" }
        return "Upcoming"
    }

    private var color: Color {
        if trip.isEnded { return .secondary }
        if trip.isActive { return OweGoTheme.positive }
        if trip.isPast { return OweGoTheme.negative }
        return OweGoTheme.primary
    }
}

struct CelebrationView: View {
    let title: String
    let message: String
    @State private var scale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(OweGoTheme.positive)
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(OweGoTheme.spring) { scale = 1.0 }
                    Haptic.success()
                }
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(OweGoTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(OweGoTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String?
    var trailingAction: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(OweGoTheme.textPrimary)
            Spacer()
            if let trailing, let trailingAction {
                Button(trailing, action: trailingAction)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OweGoTheme.primary)
            }
        }
    }
}
