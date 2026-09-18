import SwiftUI

struct SettlementView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let debt: SimplifiedDebt
    let onSettled: () -> Void

    @State private var copied = false
    @State private var errorMessage: String?

    /// Organizer Venmo is only useful when they are the creditor (someone pays them).
    private var organizerIsCreditor: Bool {
        guard let currentUser = trip.currentUser else { return false }
        return debt.toParticipantId == currentUser.id
    }

    private var showVenmoPay: Bool {
        AppSettings.hasVenmoHandle && organizerIsCreditor
    }

    private var showVenmoRequest: Bool {
        AppSettings.hasVenmoHandle && organizerIsCreditor
    }

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            HStack(spacing: 16) {
                ParticipantAvatar(name: debt.fromName, size: 48)
                Image(systemName: "arrow.right")
                    .foregroundStyle(OweGoTheme.textSecondary)
                ParticipantAvatar(name: debt.toName, size: 48)
            }

            VStack(spacing: 4) {
                Text("\(debt.fromName) owes \(debt.toName)")
                    .font(.subheadline)
                    .foregroundStyle(OweGoTheme.textSecondary)
                Text(CurrencyFormatter.string(from: debt.amount))
                    .font(OweGoTheme.moneyFont(size: 40))
                    .foregroundStyle(OweGoTheme.primary)
            }

            VStack(spacing: 12) {
                OweGoPrimaryButton("Mark as Paid", icon: "checkmark.circle.fill") {
                    recordSettlement()
                }
                OweGoSecondaryButton(copied ? "Copied!" : "Copy Payment Request", icon: "doc.on.doc") {
                    copyPaymentRequest()
                }

                if showVenmoRequest {
                    Button {
                        VenmoLinkBuilder.openPayment(
                            recipientHandle: AppSettings.venmoHandle,
                            amount: debt.amount,
                            note: "\(trip.name) - \(debt.fromName)",
                            txn: .charge
                        )
                        Haptic.light()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "dollarsign.circle")
                            Text("Request on Venmo").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(OweGoTheme.primary)
                        .background(OweGoTheme.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                if showVenmoPay {
                    Button {
                        VenmoLinkBuilder.openPayment(
                            recipientHandle: AppSettings.venmoHandle,
                            amount: debt.amount,
                            note: "\(trip.name) - \(debt.fromName)",
                            txn: .pay
                        )
                        Haptic.light()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Open pay link").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(OweGoTheme.primary)
                        .background(OweGoTheme.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .owegoScreenBackground()
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func recordSettlement() {
        guard let dependencies else { return }
        do {
            _ = try dependencies.recordSettlement.execute(input: RecordSettlementInput(
                tripId: trip.id,
                fromParticipantId: debt.fromParticipantId,
                toParticipantId: debt.toParticipantId,
                amount: debt.amount
            ))
            Haptic.success()
            onSettled()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func copyPaymentRequest() {
        let payURL: URL? = {
            guard organizerIsCreditor, AppSettings.hasVenmoHandle else { return nil }
            return VenmoLinkBuilder.shareablePayURL(
                amount: debt.amount,
                note: "\(trip.name) - \(debt.fromName)"
            )
        }()

        let message = PaymentRequestBuilder.message(
            debtorName: debt.fromName,
            creditorName: debt.toName,
            amount: debt.amount,
            tripName: trip.name,
            venmoPayURL: payURL
        )
        UIPasteboard.general.string = message
        copied = true
        Haptic.light()
    }
}
