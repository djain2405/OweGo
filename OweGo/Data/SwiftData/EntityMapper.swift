import Foundation

enum EntityMapper {
    static func toDomain(_ entity: TripEntity) -> Trip {
        Trip(
            id: entity.id,
            name: entity.name,
            startDate: entity.startDate,
            endDate: entity.endDate,
            participants: entity.participants.map(toDomain),
            expenses: entity.expenses.map(toDomain),
            settlements: entity.settlements.map(toDomain),
            isEnded: entity.isEnded
        )
    }

    static func toDomain(_ entity: ParticipantEntity) -> Participant {
        var name = entity.name
        if entity.isCurrentUser {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if (trimmed.isEmpty || trimmed.caseInsensitiveCompare("You") == .orderedSame),
               AppSettings.hasConfiguredName {
                name = AppSettings.currentUserName
            }
        }
        return Participant(id: entity.id, name: name, isCurrentUser: entity.isCurrentUser)
    }

    static func toDomain(_ entity: ExpenseEntity) -> Expense {
        Expense(
            id: entity.id,
            tripId: entity.trip?.id ?? UUID(),
            amount: entity.amount,
            description: entity.expenseDescription,
            category: ExpenseCategory(rawValue: entity.categoryRaw) ?? .other,
            paidByParticipantId: entity.paidByParticipantId,
            splits: entity.splits.map(toDomain),
            notes: entity.notes,
            receiptImageData: entity.receiptImageData,
            createdAt: entity.createdAt
        )
    }

    static func toDomain(_ entity: SplitEntity) -> Split {
        Split(id: entity.id, participantId: entity.participantId, amount: entity.amount)
    }

    static func toDomain(_ entity: SettlementEntity) -> Settlement {
        Settlement(
            id: entity.id,
            tripId: entity.trip?.id ?? UUID(),
            fromParticipantId: entity.fromParticipantId,
            toParticipantId: entity.toParticipantId,
            amount: entity.amount,
            settledAt: entity.settledAt
        )
    }

    static func makeEntity(from trip: Trip) -> TripEntity {
        let entity = TripEntity(
            id: trip.id,
            name: trip.name,
            startDate: trip.startDate,
            endDate: trip.endDate,
            isEnded: trip.isEnded
        )
        apply(trip, to: entity)
        return entity
    }

    static func apply(_ trip: Trip, to entity: TripEntity) {
        entity.id = trip.id
        entity.name = trip.name
        entity.startDate = trip.startDate
        entity.endDate = trip.endDate
        entity.isEnded = trip.isEnded

        entity.participants = trip.participants.map { participant in
            let participantEntity = ParticipantEntity(
                id: participant.id,
                name: participant.name,
                isCurrentUser: participant.isCurrentUser,
                trip: entity
            )
            return participantEntity
        }

        entity.expenses = trip.expenses.map { expense in
            let expenseEntity = ExpenseEntity(
                id: expense.id,
                amount: expense.amount,
                expenseDescription: expense.description,
                categoryRaw: expense.category.rawValue,
                paidByParticipantId: expense.paidByParticipantId,
                notes: expense.notes,
                receiptImageData: expense.receiptImageData,
                createdAt: expense.createdAt,
                trip: entity,
                splits: expense.splits.map { split in
                    SplitEntity(id: split.id, participantId: split.participantId, amount: split.amount)
                }
            )
            for splitEntity in expenseEntity.splits {
                splitEntity.expense = expenseEntity
            }
            return expenseEntity
        }

        entity.settlements = trip.settlements.map { settlement in
            SettlementEntity(
                id: settlement.id,
                fromParticipantId: settlement.fromParticipantId,
                toParticipantId: settlement.toParticipantId,
                amount: settlement.amount,
                settledAt: settlement.settledAt,
                trip: entity
            )
        }
    }
}
