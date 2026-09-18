import SwiftUI
import PhotosUI

struct AddExpenseView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let onSaved: () -> Void

    @State private var amountText = ""
    @State private var description = ""
    @State private var category: ExpenseCategory = .other
    @State private var paidByParticipantId: UUID
    @State private var selectedParticipantIds: Set<UUID>
    @State private var splitMode: SplitModeType = .equal
    @State private var customAmounts: [UUID: String] = [:]
    @State private var percentages: [UUID: String] = [:]
    @State private var notes = ""
    @State private var showMoreOptions = false
    @State private var showConfirmation = false
    @State private var savedExpense: Expense?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var receiptImageData: Data?
    @State private var errorMessage: String?

    enum SplitModeType: String, CaseIterable, Identifiable {
        case equal = "Equally"
        case custom = "Custom amounts"
        case percentage = "Percentages"

        var id: String { rawValue }
    }

    init(trip: Trip, onSaved: @escaping () -> Void) {
        self.trip = trip
        self.onSaved = onSaved
        let currentUserId = trip.currentUser?.id ?? trip.participants.first?.id ?? UUID()
        _paidByParticipantId = State(initialValue: currentUserId)
        _selectedParticipantIds = State(initialValue: Set(trip.participants.map(\.id)))
    }

    var body: some View {
        NavigationStack {
            if showConfirmation, let expense = savedExpense {
                confirmationView(for: expense)
            } else {
                entryView
            }
        }
    }

    private var entryView: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("How much?")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(OweGoTheme.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(OweGoTheme.moneyFont(size: 32))
                    .foregroundStyle(OweGoTheme.textSecondary)
                TextField("0", text: $amountText)
                    .font(OweGoTheme.moneyFont(size: 56))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 16)

            HStack(spacing: 8) {
                DefaultPill(text: paidByLabel)
                DefaultPill(text: "Everyone")
                DefaultPill(text: "Equally")
            }
            .padding(.bottom, 24)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    showMoreOptions = true
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("More options")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(OweGoTheme.primary)
                }

                OweGoPrimaryButton("Save", icon: "checkmark") {
                    saveExpense()
                }
                .disabled(!isValidAmount)
                .opacity(isValidAmount ? 1 : 0.5)
            }
            .padding()
        }
        .owegoScreenBackground()
        .navigationTitle("Log expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .sheet(isPresented: $showMoreOptions) {
            moreOptionsSheet
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    receiptImageData = data
                }
            }
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

    private var moreOptionsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        TextField("Description", text: $description)
                            .textFieldStyle(.roundedBorder)
                        Picker("Category", selection: $category) {
                            ForEach(ExpenseCategory.allCases) { cat in
                                Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                            }
                        }
                        Picker("Paid by", selection: $paidByParticipantId) {
                            ForEach(trip.participants) { participant in
                                Text(participant.displayName)
                                    .tag(participant.id)
                            }
                        }
                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(16)
                    .owegoCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Split")
                            .font(.headline)
                        participantSelection
                        Picker("Split mode", selection: $splitMode) {
                            ForEach(SplitModeType.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        if splitMode == .custom { customAmountFields }
                        else if splitMode == .percentage { percentageFields }
                    }
                    .padding(16)
                    .owegoCard()

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(
                            receiptImageData == nil ? "Add receipt photo" : "Receipt attached",
                            systemImage: "camera"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                        .owegoCard()
                    }
                }
                .padding()
            }
            .owegoScreenBackground()
            .navigationTitle("More options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showMoreOptions = false }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var paidByLabel: String {
        if let p = trip.participants.first(where: { $0.id == paidByParticipantId }) {
            return "\(p.displayName) paid"
        }
        return "Paid"
    }

    private var participantSelection: some View {
        ForEach(trip.participants) { participant in
            Toggle(isOn: Binding(
                get: { selectedParticipantIds.contains(participant.id) },
                set: { isOn in
                    if isOn { selectedParticipantIds.insert(participant.id) }
                    else if selectedParticipantIds.count > 1 { selectedParticipantIds.remove(participant.id) }
                }
            )) {
                Text(participant.displayName)
            }
        }
    }

    private var customAmountFields: some View {
        ForEach(selectedParticipants) { participant in
            HStack {
                Text(participant.displayName)
                Spacer()
                TextField("0.00", text: Binding(
                    get: { customAmounts[participant.id, default: ""] },
                    set: { customAmounts[participant.id] = $0 }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            }
        }
    }

    private var percentageFields: some View {
        ForEach(selectedParticipants) { participant in
            HStack {
                Text(participant.displayName)
                Spacer()
                TextField("0", text: Binding(
                    get: { percentages[participant.id, default: ""] },
                    set: { percentages[participant.id] = $0 }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                Text("%")
            }
        }
    }

    private func confirmationView(for expense: Expense) -> some View {
        let participantCount = expense.splits.count
        let currentUserId = trip.currentUser?.id
        let yourShare = expense.splits.first(where: { $0.participantId == currentUserId })?.amount ?? 0
        let othersOwe = expense.amount - yourShare

        return VStack(spacing: 24) {
            Spacer()
            CelebrationView(
                title: "Logged!",
                message: "\(CurrencyFormatter.string(from: expense.amount)) split \(participantCount) ways"
            )
            VStack(spacing: 8) {
                Text("Your part: \(CurrencyFormatter.string(from: yourShare))")
                    .font(.headline)
                if paidByParticipantId == currentUserId {
                    Text("Others owe you \(CurrencyFormatter.string(from: othersOwe))")
                        .font(.subheadline)
                        .foregroundStyle(OweGoTheme.positive)
                }
            }
            Spacer()
            OweGoPrimaryButton("Done") {
                onSaved()
                dismiss()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .owegoScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectedParticipants: [Participant] {
        trip.participants.filter { selectedParticipantIds.contains($0.id) }
    }

    private var isValidAmount: Bool {
        parsedAmount != nil && (parsedAmount ?? 0) > 0
    }

    private var parsedAmount: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }

    private func saveExpense() {
        guard let dependencies, let amount = parsedAmount else { return }
        do {
            let mode = try buildSplitMode(amount: amount)
            let expense = try dependencies.addExpense.execute(input: AddExpenseInput(
                tripId: trip.id,
                amount: amount,
                description: description,
                category: category,
                paidByParticipantId: paidByParticipantId,
                participantIds: Array(selectedParticipantIds),
                splitMode: mode,
                notes: notes.isEmpty ? nil : notes,
                receiptImageData: receiptImageData
            ))
            savedExpense = expense
            showConfirmation = true
            Haptic.light()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func buildSplitMode(amount: Decimal) throws -> SplitMode {
        switch splitMode {
        case .equal: return .equal
        case .custom:
            var amounts: [UUID: Decimal] = [:]
            for participant in selectedParticipants {
                guard let text = customAmounts[participant.id],
                      let value = Decimal(string: text), value >= 0 else {
                    throw TripError.invalidInput("Enter a valid custom amount for each participant.")
                }
                amounts[participant.id] = value
            }
            guard amounts.values.reduce(0, +) == amount else {
                throw TripError.invalidInput("Custom amounts must add up to \(CurrencyFormatter.string(from: amount)).")
            }
            return .customAmounts(amounts)
        case .percentage:
            var values: [UUID: Decimal] = [:]
            for participant in selectedParticipants {
                guard let text = percentages[participant.id],
                      let value = Decimal(string: text), value >= 0 else {
                    throw TripError.invalidInput("Enter a valid percentage for each participant.")
                }
                values[participant.id] = value
            }
            guard values.values.reduce(0, +) > 0 else {
                throw TripError.invalidInput("Percentages must add up to more than zero.")
            }
            return .percentages(values)
        }
    }
}

private struct DefaultPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(OweGoTheme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(OweGoTheme.primary.opacity(0.1))
            .clipShape(Capsule())
    }
}
