import Foundation

enum ExpenseParserError: LocalizedError {
    case unsupportedCategory
    case amountNotFound
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .unsupportedCategory:
            return "没有识别到支持的记账大类，目前只支持餐饮、交通、购物、娱乐、看病。"
        case .amountNotFound:
            return "没有识别到金额，请在语音里说出具体花费。"
        case .invalidAmount:
            return "金额格式不正确，请重新说一次，例如“餐饮 午饭 35元”。"
        }
    }
}

enum ExpenseParser {
    private static let amountPattern = #"\d+(?:\.\d{1,2})?"#
    private static let chineseAmountPattern = #"[零一二两三四五六七八九十百千万点块元毛角]+(?:块钱|块|元|毛|角)?"#

    static func parse(text: String, categories: [ExpenseCategory]) throws -> VoiceParseResult {
        let normalized = normalize(text)
        guard let categoryMatch = findCategory(in: normalized, categories: categories) else {
            throw ExpenseParserError.unsupportedCategory
        }

        guard let amountMatch = findAmount(in: normalized) else {
            throw ExpenseParserError.amountNotFound
        }

        guard amountMatch > 0 else {
            throw ExpenseParserError.invalidAmount
        }

        let detail = extractDetail(
            from: normalized,
            category: categoryMatch.category,
            matchedAlias: categoryMatch.alias,
            amountSnippet: categoryMatch.amountSnippet ?? ""
        )

        return VoiceParseResult(
            category: categoryMatch.category,
            detail: detail,
            amount: amountMatch,
            originalText: text
        )
    }

    private static func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "，", with: " ")
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: "。", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "：", with: " ")
            .replacingOccurrences(of: ":", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func findCategory(in text: String, categories: [ExpenseCategory]) -> (category: ExpenseCategory, alias: String, amountSnippet: String?)? {
        for category in categories {
            for alias in category.keywords where text.contains(alias) {
                return (category, alias, nil)
            }
        }
        return nil
    }

    private static func findAmount(in text: String) -> Decimal? {
        if let range = text.range(of: amountPattern, options: .regularExpression) {
            return Decimal(string: String(text[range]))
        }

        let matches = text.matches(for: chineseAmountPattern)
        for match in matches.sorted(by: { $0.count > $1.count }) {
            if let value = ChineseNumberParser.parse(match) {
                return value
            }
        }
        return nil
    }

    private static func extractDetail(
        from text: String,
        category: ExpenseCategory,
        matchedAlias: String,
        amountSnippet: String
    ) -> String {
        var content = text
        let removableWords = Set(
            category.keywords
            + ["花了", "消费", "用了", "支出", "今天", "刚刚", "买了", "付款", "元", "块", "块钱"]
        )

        if !amountSnippet.isEmpty {
            content = content.replacingOccurrences(of: amountSnippet, with: " ")
        }

        if let numberRange = content.range(of: amountPattern, options: .regularExpression) {
            content.removeSubrange(numberRange)
        }

        let chineseMatches = content.matches(for: chineseAmountPattern)
        for match in chineseMatches {
            if ChineseNumberParser.parse(match) != nil {
                content = content.replacingOccurrences(of: match, with: " ")
            }
        }

        content = content.replacingOccurrences(of: matchedAlias, with: " ")
        for word in removableWords {
            content = content.replacingOccurrences(of: word, with: " ")
        }

        let cleaned = content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return cleaned.isEmpty ? defaultDetail(for: category) : cleaned
    }

    private static func defaultDetail(for category: ExpenseCategory) -> String {
        switch category.name {
        case "餐饮":
            return "日常餐饮"
        case "交通":
            return "日常交通"
        case "购物":
            return "日常购物"
        case "娱乐":
            return "休闲娱乐"
        case "看病":
            return "医疗支出"
        default:
            return "\(category.name)支出"
        }
    }
}

private extension String {
    func matches(for regex: String) -> [String] {
        guard let expression = try? NSRegularExpression(pattern: regex) else { return [] }
        let range = NSRange(startIndex..<endIndex, in: self)
        return expression.matches(in: self, range: range).compactMap { result in
            guard let range = Range(result.range, in: self) else { return nil }
            return String(self[range])
        }
    }
}
