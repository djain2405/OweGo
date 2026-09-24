import SwiftUI

struct ShareTripReportView: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let summary: TripBalanceSummary

    @State private var selectedParticipantId: UUID?
    @State private var csvURL: URL?
    @State private var exportError: String?

    private var groupReportText: String {
        TripReportBuilder.groupReport(trip: trip, summary: summary)
    }

    private var selectedParticipant: Participant? {
        guard let selectedParticipantId else { return nil }
        return trip.participants.first(where: { $0.id == selectedParticipantId })
    }

    private var memberReportText: String? {
        guard let participant = selectedParticipant else { return nil }
        return TripReportBuilder.memberReport(
            trip: trip,
            summary: summary,
            participant: participant
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ShareLink(
                        item: groupReportText,
                        subject: Text("\(trip.name) trip wrap-up"),
                        message: Text("Hey crew, trip wrap-up from OweGoGo")
                    ) {
                        Label("Share Group Report", systemImage: "person.3")
                    }
                } header: {
                    Text("Group")
                } footer: {
                    Text("Settle-ups plus every expense and who paid, for the whole crew.")
                }

                Section {
                    Picker("Person", selection: $selectedParticipantId) {
                        Text("Choose…").tag(Optional<UUID>.none)
                        ForEach(trip.participants) { participant in
                            Text(participant.name).tag(Optional(participant.id))
                        }
                    }

                    if let memberReportText, let participant = selectedParticipant {
                        let firstName = participant.displayName.split(separator: " ").first.map(String.init) ?? participant.displayName
                        ShareLink(
                            item: memberReportText,
                            subject: Text("\(participant.name) \(trip.name)"),
                            message: Text("Hi \(firstName), your trip tab from OweGoGo")
                        ) {
                            Label("Share \(participant.name)’s Report", systemImage: "person.crop.circle")
                        }
                    }
                } header: {
                    Text("Personalized")
                } footer: {
                    Text("Just their balance, settle-ups, and the expenses they were on.")
                }

                Section {
                    if let csvURL {
                        ShareLink(item: csvURL) {
                            Label("Export Spreadsheet", systemImage: "tablecells")
                        }
                    } else {
                        Button {
                            prepareCSV()
                        } label: {
                            Label("Prepare Spreadsheet", systemImage: "tablecells")
                        }
                    }
                } header: {
                    Text("Spreadsheet")
                } footer: {
                    Text("CSV file that opens in Excel, Numbers, or Google Sheets.")
                }
            }
            .navigationTitle("Share / Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if selectedParticipantId == nil {
                    selectedParticipantId = trip.currentUser?.id ?? trip.participants.first?.id
                }
                prepareCSV()
            }
            .alert("Export Error", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "")
            }
        }
    }

    private func prepareCSV() {
        do {
            csvURL = try TripSpreadsheetExporter.exportCSV(trip: trip, summary: summary)
        } catch {
            exportError = error.localizedDescription
            csvURL = nil
        }
    }
}
