import SwiftUI

struct TripDashboardView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    let tripId: UUID
    let onTripUpdated: () -> Void
    let onTripDeleted: () -> Void

    @State private var trip: Trip
    @State private var summary: TripBalanceSummary
    @State private var showingAddExpense = false
    @State private var selectedDebt: SimplifiedDebt?
    @State private var showingCompletion = false
    @State private var showingEditTrip = false
    @State private var showingDeleteConfirm = false
    @State private var showingShareExport = false
    @State private var errorMessage: String?
    @State private var expenseAppear = false

    init(trip: Trip, onTripUpdated: @escaping () -> Void, onTripDeleted: @escaping () -> Void = {}) {
        self.tripId = trip.id
        self.onTripUpdated = onTripUpdated
        self.onTripDeleted = onTripDeleted
        _trip = State(initialValue: trip)
        _summary = State(initialValue: BalanceEngine.computeSummary(for: trip))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    tripStatusBanner
                    statsSection
                    balancesSection
                    expensesSection
                }
                .padding()
                .padding(.bottom, 88)
            }

            OweGoFAB(title: "Log it", icon: "plus") {
                showingAddExpense = true
            }
            .padding(.bottom, 24)
        }
        .owegoScreenBackground()
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(OweGoTheme.surface.opacity(0.92), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingShareExport = true
                    } label: {
                        Label("Share / Export…", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showingEditTrip = true
                    } label: {
                        Label("Edit Trip", systemImage: "pencil")
                    }
                    if trip.isPast && !trip.isEnded {
                        Button {
                            endTrip()
                        } label: {
                            Label("End Trip", systemImage: "flag.checkered")
                        }
                    }
                    if trip.isEnded || trip.isPast {
                        Button {
                            showingCompletion = true
                        } label: {
                            Label("View Summary", systemImage: "chart.bar.doc.horizontal")
                        }
                    }
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete Trip", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(OweGoTheme.primary)
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(trip: trip) {
                reloadTrip()
            }
        }
        .sheet(item: $selectedDebt) { debt in
            SettlementView(trip: trip, debt: debt) {
                reloadTrip()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingCompletion) {
            TripCompletionView(trip: trip, summary: summary)
        }
        .sheet(isPresented: $showingShareExport) {
            ShareTripReportView(trip: trip, summary: summary)
        }
        .sheet(isPresented: $showingEditTrip) {
            TripFormView(mode: .edit(trip), onSaved: { updated in
                trip = updated
                reloadTrip()
                showingEditTrip = false
            }, onDeleted: {
                onTripDeleted()
                dismiss()
            })
        }
        .confirmationDialog(
            "Delete \"\(trip.name)\"?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Trip", role: .destructive) { deleteTrip() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all expenses and balances. This can't be undone.")
        }
        .onAppear {
            reloadTrip()
            Task { await NotificationManager.requestAuthorization() }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var tripStatusBanner: some View {
        Group {
            if trip.isActive {
                activeTripBanner
            } else if trip.isPast || trip.isEnded {
                endedTripBanner
            } else {
                upcomingTripBanner
            }
        }
    }

    private var activeTripBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ActiveTripDot()
                Text("Live trip")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.95))
                Spacer()
                Text("\(trip.participants.count) people")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            Text(trip.name)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(DateFormatterHelper.tripDateRange(start: trip.startDate, end: trip.endDate))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))
            ParticipantAvatarRow(participants: trip.participants)
                .padding(.top, 2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .bottomTrailing) {
                OweGoTheme.heroGradient
                OweGoTheme.heroOverlay
                Image(systemName: "figure.hiking")
                    .font(.system(size: 72, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.14))
                    .offset(x: 8, y: 10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: OweGoTheme.cardRadius + 2, style: .continuous))
        .shadow(color: OweGoTheme.primary.opacity(0.28), radius: 14, x: 0, y: 6)
    }

    private var upcomingTripBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Coming up")
                .font(.caption.weight(.bold))
                .foregroundStyle(OweGoTheme.primary)
            Text(trip.name)
                .font(.title3.weight(.bold))
                .foregroundStyle(OweGoTheme.textPrimary)
            Text(DateFormatterHelper.countdownPhrase(until: trip.startDate))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(OweGoTheme.textSecondary)
            Text(DateFormatterHelper.tripDateRange(start: trip.startDate, end: trip.endDate))
                .font(.caption)
                .foregroundStyle(OweGoTheme.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .owegoUpcomingCard()
    }

    private var endedTripBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trip.isEnded ? "Trip ended" : "Trip over")
                .font(.caption.weight(.bold))
                .foregroundStyle(OweGoTheme.textSecondary)
            Text(trip.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(OweGoTheme.textPrimary.opacity(0.9))
            Text(DateFormatterHelper.tripDateRange(start: trip.startDate, end: trip.endDate))
                .font(.subheadline)
                .foregroundStyle(OweGoTheme.textSecondary)
            if summary.isFullySettled {
                Text("All settled")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(OweGoTheme.positive)
            } else {
                Text("\(summary.remainingDebtCount) balances still open")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(OweGoTheme.negative)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .owegoPastCard()
    }

    private var statsSection: some View {
        Group {
            if let currentUser = trip.currentUser,
               let ledger = summary.ledgers.first(where: { $0.participantId == currentUser.id }) {
                BalanceHero(
                    userName: currentUser.displayName,
                    balance: ledger.balance,
                    paid: ledger.paid,
                    totalSpent: summary.totalSpent,
                    onSettle: preferredSettlementDebt == nil ? nil : {
                        selectedDebt = preferredSettlementDebt
                    }
                )
            }
        }
    }

    private var balancesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                SectionHeader(
                    title: "Who owes what",
                    trailing: settleTrailingTitle,
                    trailingAction: settleTrailingAction
                )
                if !summary.simplifiedDebts.isEmpty {
                    Text("Settle these to finish the trip")
                        .font(.caption)
                        .foregroundStyle(OweGoTheme.textSecondary)
                }
            }

            if summary.simplifiedDebts.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(OweGoTheme.positive)
                    Text("All settled. Nothing left to do.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(OweGoTheme.positive)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(OweGoTheme.positiveBackground)
                .clipShape(RoundedRectangle(cornerRadius: OweGoTheme.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: OweGoTheme.cardRadius, style: .continuous)
                        .stroke(OweGoTheme.positive.opacity(0.25), lineWidth: 1)
                )
            } else {
                ForEach(summary.simplifiedDebts) { debt in
                    debtRow(for: debt)
                }
            }
        }
    }

    @ViewBuilder
    private func debtRow(for debt: SimplifiedDebt) -> some View {
        let reason = TripStoryHelpers.pairContextSubtitle(
            fromParticipantId: debt.fromParticipantId,
            toParticipantId: debt.toParticipantId,
            on: trip
        )

        if let currentUser = trip.currentUser,
           debt.fromParticipantId == currentUser.id || debt.toParticipantId == currentUser.id {
            Button {
                selectedDebt = debt
            } label: {
                PersonBalanceCard(
                    otherName: debt.fromParticipantId == currentUser.id ? debt.toName : debt.fromName,
                    selfName: currentUser.displayName,
                    amount: debt.amount,
                    isOwedToYou: debt.toParticipantId == currentUser.id,
                    reason: reason
                )
            }
            .buttonStyle(.plain)
        } else {
            PeerDebtCard(
                fromName: debt.fromName,
                toName: debt.toName,
                amount: debt.amount,
                reason: reason
            )
        }
    }

    private var settleTrailingTitle: String? {
        preferredSettlementDebt == nil ? nil : "Settle"
    }

    private var settleTrailingAction: (() -> Void)? {
        guard preferredSettlementDebt != nil else { return nil }
        return {
            selectedDebt = preferredSettlementDebt
        }
    }

    /// Settle only opens debts involving the current user (peer debts stay view-only).
    private var preferredSettlementDebt: SimplifiedDebt? {
        guard let currentUser = trip.currentUser else { return nil }
        return summary.simplifiedDebts.first(where: {
            $0.fromParticipantId == currentUser.id || $0.toParticipantId == currentUser.id
        })
    }

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Recent moments")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(OweGoTheme.textPrimary)
                Text("What the group spent along the way")
                    .font(.caption)
                    .foregroundStyle(OweGoTheme.textSecondary)
            }

            if trip.expenses.isEmpty {
                Text("No expenses yet. Tap Log it to add your first one.")
                    .font(.subheadline)
                    .foregroundStyle(OweGoTheme.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .owegoCard()
            } else {
                ForEach(Array(trip.expenses.sorted(by: { $0.createdAt > $1.createdAt }).enumerated()), id: \.element.id) { index, expense in
                    NavigationLink {
                        ExpenseDetailView(trip: trip, expense: expense) {
                            reloadTrip()
                        }
                    } label: {
                        ExpenseCard(
                            expense: expense,
                            payerName: payerName(for: expense.paidByParticipantId)
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(expenseAppear ? 1 : 0)
                    .offset(y: expenseAppear ? 0 : 6)
                    .animation(OweGoTheme.spring.delay(Double(index) * 0.04), value: expenseAppear)
                }
            }
        }
        .onAppear { expenseAppear = true }
    }

    private func payerName(for id: UUID) -> String {
        trip.participants.first(where: { $0.id == id })?.displayName ?? "Unknown"
    }

    private func reloadTrip() {
        guard let dependencies else { return }
        do {
            if let updated = try dependencies.tripRepository.fetch(id: tripId) {
                trip = updated
                summary = BalanceEngine.computeSummary(for: updated)
                NotificationManager.scheduleTripNotifications(for: updated, summary: summary)
                onTripUpdated()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func endTrip() {
        guard let dependencies else { return }
        do {
            trip = try dependencies.endTrip.execute(tripId: tripId)
            summary = BalanceEngine.computeSummary(for: trip)
            showingCompletion = true
            onTripUpdated()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteTrip() {
        guard let dependencies else { return }
        do {
            try dependencies.deleteTrip.execute(tripId: tripId)
            Haptic.medium()
            onTripDeleted()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
