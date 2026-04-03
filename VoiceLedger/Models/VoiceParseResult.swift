import Foundation

struct VoiceParseResult {
    let category: ExpenseCategory
    let detail: String
    let amount: Decimal
    let originalText: String

    var entry: ExpenseEntry {
        ExpenseEntry(category: category, detail: detail, amount: amount)
    }
}
