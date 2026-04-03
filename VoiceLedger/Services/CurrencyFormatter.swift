import Foundation

enum CurrencyFormatter {
    static func string(from amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: amount as NSDecimalNumber) ?? "¥0.00"
    }
}
