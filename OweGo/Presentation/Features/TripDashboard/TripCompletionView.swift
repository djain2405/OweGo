import SwiftUI

struct TripCompletionView: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let summary: TripBalanceSummary

    @State private var showingShareExport = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(trip.name) is over")
                            .font(.title.weight(.bold))
                        Text("\(summary.expenseCount) expenses · \(CurrencyFormatter.string(from: summary.totalSpent)) total spent")
                            .foregroundStyle(OweGoTheme.textSecondary)
                    }

                    if summary.isFullySettled {
                        CelebrationView(
                            title: "All settled!",
                            message: "Nothing left to do. Great trip."
                        )
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .owegoCard()
                    } else {
                        Text("\(summary.remainingDebtCount) balances remaining")
                            .font(.headline)

                        ForEach(summary.simplifiedDebts) { debt in
                            HStack {
                                ParticipantAvatar(name: debt.fromName, size: 32)
                                Text("→")
                                    .foregroundStyle(OweGoTheme.textSecondary)
                                ParticipantAvatar(name: debt.toName, size: 32)
                                Spacer()
                                Text(CurrencyFormatter.string(from: debt.amount))
                                    .fontWeight(.semibold)
                            }
                            .padding(14)
                            .owegoCard()
                        }
                    }

                    if !summary.ledgers.isEmpty {
                        Text("Final ledger")
                            .font(.headline)
                            .padding(.top, 8)

                        ForEach(summary.ledgers) { ledger in
                            HStack {
                                ParticipantAvatar(name: ledger.name, size: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ledger.name)
                                        .fontWeight(.medium)
                                    Text("Fronted \(CurrencyFormatter.string(from: ledger.paid)) · Part \(CurrencyFormatter.string(from: ledger.share))")
                                        .font(.caption)
                                        .foregroundStyle(OweGoTheme.textSecondary)
                                }
                                Spacer()
                                Text(CurrencyFormatter.string(from: ledger.balance))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(ledger.balance >= 0 ? OweGoTheme.positive : OweGoTheme.negative)
                            }
                            .padding(14)
                            .owegoCard()
                        }
                    }

                    Button {
                        showingShareExport = true
                    } label: {
                        Label("Share / Export…", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OweGoTheme.primary)
                }
                .padding()
            }
            .owegoScreenBackground()
            .navigationTitle("Trip Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingShareExport = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingShareExport) {
                ShareTripReportView(trip: trip, summary: summary)
            }
        }
    }
}
