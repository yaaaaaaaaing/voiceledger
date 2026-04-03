import Foundation

struct ExpenseEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let category: ExpenseCategory
    let detail: String
    let amount: Decimal
    let createdAt: Date

    init(
        id: UUID = UUID(),
        category: ExpenseCategory,
        detail: String,
        amount: Decimal,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.detail = detail
        self.amount = amount
        self.createdAt = createdAt
    }
}
