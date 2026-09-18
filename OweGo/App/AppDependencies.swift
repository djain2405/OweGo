import SwiftUI
import SwiftData

@MainActor
final class AppDependencies {
    let tripRepository: LocalTripRepository

    init(modelContext: ModelContext) {
        tripRepository = LocalTripRepository(modelContext: modelContext)
    }

    var createTrip: CreateTripUseCase {
        CreateTripUseCase(tripRepository: tripRepository)
    }

    var addExpense: AddExpenseUseCase {
        AddExpenseUseCase(tripRepository: tripRepository, expenseRepository: tripRepository)
    }

    var updateExpense: UpdateExpenseUseCase {
        UpdateExpenseUseCase(tripRepository: tripRepository, expenseRepository: tripRepository)
    }

    var deleteExpense: DeleteExpenseUseCase {
        DeleteExpenseUseCase(expenseRepository: tripRepository)
    }

    var recordSettlement: RecordSettlementUseCase {
        RecordSettlementUseCase(tripRepository: tripRepository, settlementRepository: tripRepository)
    }

    var endTrip: EndTripUseCase {
        EndTripUseCase(tripRepository: tripRepository)
    }

    var updateTrip: UpdateTripUseCase {
        UpdateTripUseCase(tripRepository: tripRepository)
    }

    var deleteTrip: DeleteTripUseCase {
        DeleteTripUseCase(tripRepository: tripRepository)
    }
}

private struct DependenciesKey: EnvironmentKey {
    static let defaultValue: AppDependencies? = nil
}

extension EnvironmentValues {
    var dependencies: AppDependencies? {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}
