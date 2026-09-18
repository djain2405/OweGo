import Foundation

enum SplitMode: Equatable {
    case equal
    case customAmounts([UUID: Decimal])
    case percentages([UUID: Decimal])
}
