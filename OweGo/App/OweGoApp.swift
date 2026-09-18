import SwiftUI
import SwiftData

@main
struct OweGoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TripEntity.self,
            ParticipantEntity.self,
            ExpenseEntity.self,
            SplitEntity.self,
            SettlementEntity.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TripListView()
                .tint(OweGoTheme.primary)
                .preferredColorScheme(.light)
                .environment(\.dependencies, AppDependencies(modelContext: sharedModelContainer.mainContext))
        }
        .modelContainer(sharedModelContainer)
    }
}
