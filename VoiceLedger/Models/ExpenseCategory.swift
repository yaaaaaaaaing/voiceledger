import Foundation

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case dining = "餐饮"
    case transport = "交通"
    case shopping = "购物"
    case entertainment = "娱乐"
    case medical = "看病"

    var id: String { rawValue }

    var aliases: [String] {
        switch self {
        case .dining:
            return ["餐饮", "吃饭", "午饭", "晚饭", "早餐", "宵夜", "咖啡", "奶茶"]
        case .transport:
            return ["交通", "打车", "地铁", "公交", "高铁", "火车", "机票", "加油", "停车"]
        case .shopping:
            return ["购物", "买", "超市", "日用品", "衣服", "鞋子", "网购"]
        case .entertainment:
            return ["娱乐", "电影", "游戏", "唱歌", "旅游", "聚会"]
        case .medical:
            return ["看病", "医院", "挂号", "买药", "药店", "体检", "门诊"]
        }
    }

    var colorName: String {
        switch self {
        case .dining:
            return "orange"
        case .transport:
            return "blue"
        case .shopping:
            return "pink"
        case .entertainment:
            return "purple"
        case .medical:
            return "green"
        }
    }
}
