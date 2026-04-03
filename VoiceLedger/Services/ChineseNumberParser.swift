import Foundation

enum ChineseNumberParser {
    private static let digits: [Character: Int] = [
        "零": 0, "一": 1, "二": 2, "两": 2, "三": 3, "四": 4,
        "五": 5, "六": 6, "七": 7, "八": 8, "九": 9
    ]

    private static let units: [Character: Int] = [
        "十": 10, "百": 100, "千": 1000
    ]

    static func parse(_ text: String) -> Decimal? {
        let normalized = text
            .replacingOccurrences(of: "块钱", with: "")
            .replacingOccurrences(of: "块", with: "")
            .replacingOccurrences(of: "元", with: "")
            .replacingOccurrences(of: "毛", with: "")
            .replacingOccurrences(of: "角", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else { return nil }
        if normalized.contains("点") {
            let parts = normalized.split(separator: "点", omittingEmptySubsequences: false)
            guard let integerPart = parseInteger(String(parts.first ?? "")) else { return nil }
            let decimalDigits = parts.count > 1 ? parts[1].compactMap { digits[$0] } : []
            let decimalString = decimalDigits.map(String.init).joined()
            let fullString = decimalString.isEmpty ? "\(integerPart)" : "\(integerPart).\(decimalString)"
            return Decimal(string: fullString)
        }

        guard let integer = parseInteger(normalized) else { return nil }
        return Decimal(integer)
    }

    private static func parseInteger(_ text: String) -> Int? {
        guard !text.isEmpty else { return nil }
        var result = 0
        var current = 0

        for char in text {
            if let digit = digits[char] {
                current = digit
            } else if let unit = units[char] {
                let base = current == 0 ? 1 : current
                result += base * unit
                current = 0
            } else {
                return nil
            }
        }

        return result + current
    }
}
