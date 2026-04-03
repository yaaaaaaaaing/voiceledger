import Foundation

struct VoiceParseResult {
    let category: ExpenseCategory
    var detail: String
    var amount: Decimal
    let originalText: String

    var entry: ExpenseEntry {
        ExpenseEntry(categoryName: category.name, detail: detail, amount: amount)
    }
}
