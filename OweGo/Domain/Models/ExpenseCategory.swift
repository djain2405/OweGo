import Foundation

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case food = "Food"
    case transport = "Transport"
    case lodging = "Lodging"
    case activities = "Activities"
    case supplies = "Supplies"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .lodging: return "bed.double.fill"
        case .activities: return "figure.hiking"
        case .supplies: return "bag.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}
