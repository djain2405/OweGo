import SwiftUI

struct TripListView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var trips: [Trip] = []
    @State private var navigationPath = NavigationPath()
    @State private var showingCreateTrip = false
    @State private var showingSettings = false
    @State private var tripToEdit: Trip?
    @State private var tripToDelete: Trip?
    @State private var errorMessage: String?

    private var activeTrip: Trip? {
        trips.first(where: { $0.isActive })
    }

    private var upcomingTrips: [Trip] {
        trips.filter { !$0.isActive && !$0.isPast && !$0.isEnded }
            .sorted { $0.startDate < $1.startDate }
    }

    private var pastTrips: [Trip] {
        trips.filter { $0.isPast || $0.isEnded }
            .sorted { $0.endDate > $1.endDate }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if trips.isEmpty {
                        EmptyStateView(
                            title: "Your next adventure starts here",
                            message: "Create a trip to start tracking shared expenses with your group.",
                            systemImage: "suitcase.fill",
                            actionTitle: "Create Trip",
                            action: { showingCreateTrip = true },
                            logoAssetName: "OweGoLogo"
                        )
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 28) {
                                if let activeTrip {
                                    NavigationLink(value: activeTrip.id) {
                                        TripHeroCard(trip: activeTrip)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu { tripContextMenu(for: activeTrip) }
                                }

                                if !upcomingTrips.isEmpty {
                                    tripSection(
                                        title: "Upcoming",
                                        subtitle: upcomingSectionSubtitle
                                    ) {
                                        ForEach(Array(upcomingTrips.enumerated()), id: \.element.id) { index, trip in
                                            NavigationLink(value: trip.id) {
                                                TripUpcomingCard(trip: trip)
                                            }
                                            .buttonStyle(.plain)
                                            .contextMenu { tripContextMenu(for: trip) }
                                            .staggerAppear(index: index)
                                        }
                                    }
                                }

                                if !pastTrips.isEmpty {
                                    tripSection(
                                        title: "Past",
                                        subtitle: "Trips you’ve wrapped"
                                    ) {
                                        ForEach(Array(pastTrips.enumerated()), id: \.element.id) { index, trip in
                                            NavigationLink(value: trip.id) {
                                                TripPastCard(trip: trip)
                                            }
                                            .buttonStyle(.plain)
                                            .contextMenu { tripContextMenu(for: trip) }
                                            .staggerAppear(index: index)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .padding(.bottom, 80)
                        }
                    }
                }

                if !trips.isEmpty {
                    OweGoFAB(title: "New Trip", icon: "plus") {
                        showingCreateTrip = true
                    }
                    .padding(24)
                }
            }
            .owegoScreenBackground()
            .navigationTitle("OweGo")
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(OweGoTheme.surface.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(OweGoTheme.primary)
                    }
                }
            }
            .navigationDestination(for: UUID.self) { tripId in
                if let trip = trips.first(where: { $0.id == tripId }) {
                    TripDashboardView(trip: trip, onTripUpdated: reloadTrips) {
                        navigationPath = NavigationPath()
                    }
                }
            }
            .sheet(isPresented: $showingCreateTrip) {
                TripFormView(mode: .create) { trip in
                    reloadTrips()
                    showingCreateTrip = false
                    navigationPath.append(trip.id)
                }
            }
            .sheet(item: $tripToEdit) { trip in
                TripFormView(mode: .edit(trip), onSaved: { _ in
                    reloadTrips()
                    tripToEdit = nil
                }, onDeleted: {
                    reloadTrips()
                    tripToEdit = nil
                })
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .confirmationDialog(
                deleteTitle,
                isPresented: Binding(
                    get: { tripToDelete != nil },
                    set: { if !$0 { tripToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete Trip", role: .destructive) {
                    if let trip = tripToDelete { deleteTrip(trip) }
                }
                Button("Cancel", role: .cancel) { tripToDelete = nil }
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
            .onAppear(perform: reloadTrips)
        }
    }

    private var upcomingSectionSubtitle: String {
        guard let next = upcomingTrips.first else { return "Trips on the horizon" }
        return DateFormatterHelper.countdownPhrase(until: next.startDate)
    }

    private var deleteTitle: String {
        if let trip = tripToDelete {
            return "Delete \"\(trip.name)\"?"
        }
        return "Delete trip?"
    }

    @ViewBuilder
    private func tripSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(OweGoTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(OweGoTheme.textSecondary)
            }
            content()
        }
    }

    @ViewBuilder
    private func tripContextMenu(for trip: Trip) -> some View {
        Button {
            tripToEdit = trip
        } label: {
            Label("Edit Trip", systemImage: "pencil")
        }
        Button(role: .destructive) {
            tripToDelete = trip
        } label: {
            Label("Delete Trip", systemImage: "trash")
        }
    }

    private func reloadTrips() {
        guard let dependencies else { return }
        do {
            trips = try dependencies.tripRepository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteTrip(_ trip: Trip) {
        guard let dependencies else { return }
        do {
            try dependencies.deleteTrip.execute(tripId: trip.id)
            Haptic.medium()
            tripToDelete = nil
            reloadTrips()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct StaggerAppearModifier: ViewModifier {
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 8)
            .onAppear {
                withAnimation(OweGoTheme.spring.delay(Double(index) * 0.05)) {
                    shown = true
                }
            }
    }
}

private extension View {
    func staggerAppear(index: Int) -> some View {
        modifier(StaggerAppearModifier(index: index))
    }
}
