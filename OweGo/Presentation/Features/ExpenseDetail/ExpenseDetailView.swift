import SwiftUI
import PhotosUI
import UIKit

struct ExpenseDetailView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    @State private var expense: Expense
    let onUpdated: () -> Void

    @State private var amountText: String
    @State private var description: String
    @State private var category: ExpenseCategory
    @State private var paidByParticipantId: UUID
    @State private var selectedParticipantIds: Set<UUID>
    @State private var splitMode: AddExpenseView.SplitModeType
    @State private var customAmounts: [UUID: String] = [:]
    @State private var percentages: [UUID: String] = [:]
    @State private var notes: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var receiptImageData: Data?
    @State private var showingDeleteConfirm = false
    @State private var errorMessage: String?

    init(trip: Trip, expense: Expense, onUpdated: @escaping () -> Void) {
        self.trip = trip
        _expense = State(initialValue: expense)
        self.onUpdated = onUpdated
        _amountText = State(initialValue: "\(expense.amount)")
        _description = State(initialValue: expense.description)
        _category = State(initialValue: expense.category)
        _paidByParticipantId = State(initialValue: expense.paidByParticipantId)
        _selectedParticipantIds = State(initialValue: Set(expense.splits.map(\.participantId)))
        _splitMode = State(initialValue: .equal)
        _notes = State(initialValue: expense.notes ?? "")
        _receiptImageData = State(initialValue: expense.receiptImageData)
    }

    var body: some View {
        Form {
            Section("Amount") {
                HStack {
                    Text("$")
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }

            Section("Details") {
                TextField("Description", text: $description)
                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                    }
                }
                Picker("Paid by", selection: $paidByParticipantId) {
                    ForEach(trip.participants) { participant in
                        Text(participant.displayName).tag(participant.id)
                    }
                }
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Participants") {
                ForEach(trip.participants) { participant in
                    Toggle(isOn: Binding(
                        get: { selectedParticipantIds.contains(participant.id) },
                        set: { isOn in
                            if isOn {
                                selectedParticipantIds.insert(participant.id)
                            } else if selectedParticipantIds.count > 1 {
                                selectedParticipantIds.remove(participant.id)
                            }
                        }
                    )) {
                        Text(participant.displayName)
                    }
                }
            }

            Section("Split") {
                Picker("Mode", selection: $splitMode) {
                    ForEach(AddExpenseView.SplitModeType.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                if splitMode == .custom {
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
                } else if splitMode == .percentage {
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
            }

            if let data = receiptImageData, let image = UIImage(data: data) {
                Section("Receipt") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                }
            }

            Section {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Update receipt photo", systemImage: "camera")
                }
                Button("Delete Expense", role: .destructive) {
                    showingDeleteConfirm = true
                }
            }
        }
        .owegoScreenBackground()
        .scrollContentBackground(.hidden)
        .navigationTitle("Edit Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveChanges() }
            }
        }
        .onAppear {
            loadExistingSplitValues()
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    receiptImageData = data
                }
            }
        }
        .confirmationDialog("Delete this expense?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteExpense() }
            Button("Cancel", role: .cancel) {}
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

    private var selectedParticipants: [Participant] {
        trip.participants.filter { selectedParticipantIds.contains($0.id) }
    }

    private func loadExistingSplitValues() {
        for split in expense.splits {
            customAmounts[split.participantId] = "\(split.amount)"
        }
    }

    private func saveChanges() {
        guard let dependencies,
              let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Enter a valid amount."
            return
        }

        do {
            let mode = try buildSplitMode(amount: amount)
            _ = try dependencies.updateExpense.execute(input: UpdateExpenseInput(
                expense: expense,
                amount: amount,
                description: description,
                category: category,
                paidByParticipantId: paidByParticipantId,
                participantIds: Array(selectedParticipantIds),
                splitMode: mode,
                notes: notes.isEmpty ? nil : notes,
                receiptImageData: receiptImageData
            ))
            onUpdated()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteExpense() {
        guard let dependencies else { return }
        do {
            try dependencies.deleteExpense.execute(expenseId: expense.id, tripId: trip.id)
            onUpdated()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func buildSplitMode(amount: Decimal) throws -> SplitMode {
        switch splitMode {
        case .equal:
            return .equal
        case .custom:
            var amounts: [UUID: Decimal] = [:]
            for participant in selectedParticipants {
                guard let text = customAmounts[participant.id],
                      let value = Decimal(string: text), value >= 0 else {
                    throw TripError.invalidInput("Enter a valid custom amount for each participant.")
                }
                amounts[participant.id] = value
            }
            let total = amounts.values.reduce(0, +)
            guard total == amount else {
                throw TripError.invalidInput("Custom amounts must add up to the expense total.")
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
            return .percentages(values)
        }
    }
}
