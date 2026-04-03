import Foundation

struct ExpenseEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var categoryName: String
    var detail: String
    var amount: Decimal
    let createdAt: Date

    init(
        id: UUID = UUID(),
        categoryName: String,
        detail: String,
        amount: Decimal,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.categoryName = categoryName
        self.detail = detail
        self.amount = amount
        self.createdAt = createdAt
    }
}
