import SwiftUI

enum TripFormMode {
    case create
    case edit(Trip)

    var title: String {
        switch self {
        case .create: return "New Trip"
        case .edit: return "Edit Trip"
        }
    }

    var saveTitle: String {
        switch self {
        case .create: return "Create"
        case .edit: return "Save"
        }
    }
}

struct TripFormView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    let mode: TripFormMode
    let onSaved: (Trip) -> Void
    var onDeleted: (() -> Void)?

    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    @State private var participants: [EditableParticipant] = []
    @State private var errorMessage: String?
    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    tripDetailsCard
                    participantsCard
                    if case .edit = mode {
                        deleteButton
                    }
                }
                .padding()
            }
            .owegoScreenBackground()
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.saveTitle) { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadExisting)
            .confirmationDialog(
                deleteConfirmationTitle,
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Trip", role: .destructive) { deleteTrip() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all expenses and balances. This can't be undone.")
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
    }

    private var tripDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trip details")
                .font(.headline)
            TextField("Trip name", text: $name)
                .textFieldStyle(.roundedBorder)
            DatePicker("Start", selection: $startDate, displayedComponents: .date)
            DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
        }
        .padding(16)
        .owegoCard()
    }

    private var participantsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Who's going")
                .font(.headline)

            ForEach($participants) { $participant in
                HStack(spacing: 12) {
                    ParticipantAvatar(name: participant.name.isEmpty ? "?" : participant.name, size: 36)
                    if participant.isCurrentUser {
                        TextField("Your name", text: $participant.name)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                        Text("That’s you")
                            .font(.caption)
                            .foregroundStyle(OweGoTheme.textSecondary)
                    } else {
                        TextField("Name", text: $participant.name)
                            .textFieldStyle(.roundedBorder)
                        if canRemove(participant) {
                            Button {
                                participants.removeAll { $0.id == participant.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                        }
                    }
                }
            }

            Button {
                participants.append(EditableParticipant(name: ""))
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add person")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OweGoTheme.primary)
            }
        }
        .padding(16)
        .owegoCard()
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteConfirm = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Trip")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var deleteConfirmationTitle: String {
        if case .edit(let trip) = mode {
            return "Delete \"\(trip.name)\"?"
        }
        return "Delete this trip?"
    }

    private func loadExisting() {
        switch mode {
        case .create:
            participants = [
                EditableParticipant(from: Participant(name: AppSettings.currentUserName, isCurrentUser: true)),
                EditableParticipant(name: ""),
                EditableParticipant(name: "")
            ]
        case .edit(let trip):
            name = trip.name
            startDate = trip.startDate
            endDate = trip.endDate
            participants = trip.participants.map { EditableParticipant(from: $0) }
        }
    }

    private func canRemove(_ participant: EditableParticipant) -> Bool {
        !participant.isCurrentUser
    }

    private var canSave: Bool {
        let tripNameOk = !name.trimmingCharacters(in: .whitespaces).isEmpty
        let myName = participants.first(where: \.isCurrentUser)?.name
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let myNameOk = !myName.isEmpty && myName.caseInsensitiveCompare("You") != .orderedSame
        return tripNameOk && myNameOk
    }

    private func save() {
        guard let dependencies else { return }
        do {
            let trip: Trip
            switch mode {
            case .create:
                let myName = participants.first(where: \.isCurrentUser)?.name
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let resolvedName = myName.isEmpty ? AppSettings.currentUserName : myName
                if !resolvedName.isEmpty {
                    AppSettings.currentUserName = resolvedName
                }
                trip = try dependencies.createTrip.execute(input: CreateTripInput(
                    name: name,
                    startDate: startDate,
                    endDate: endDate,
                    participantNames: participants.filter { !$0.isCurrentUser }.map(\.name),
                    currentUserName: resolvedName.isEmpty ? "Someone" : resolvedName
                ))
                let summary = BalanceEngine.computeSummary(for: trip)
                NotificationManager.scheduleTripNotifications(for: trip, summary: summary)
            case .edit(let existing):
                if let myName = participants.first(where: \.isCurrentUser)?.name
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   !myName.isEmpty {
                    AppSettings.currentUserName = myName
                    try? CurrentUserNameSync.apply(name: myName, using: dependencies.tripRepository)
                }
                trip = try dependencies.updateTrip.execute(input: UpdateTripInput(
                    tripId: existing.id,
                    name: name,
                    startDate: startDate,
                    endDate: endDate,
                    participants: participants
                ))
                let summary = BalanceEngine.computeSummary(for: trip)
                NotificationManager.scheduleTripNotifications(for: trip, summary: summary)
            }
            Haptic.light()
            onSaved(trip)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteTrip() {
        guard let dependencies, case .edit(let trip) = mode else { return }
        do {
            try dependencies.deleteTrip.execute(tripId: trip.id)
            Haptic.medium()
            onDeleted?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
