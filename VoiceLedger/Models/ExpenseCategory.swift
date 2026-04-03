import Foundation

struct ExpenseCategory: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var aliases: [String]

    init(id: UUID = UUID(), name: String, aliases: [String]) {
        self.id = id
        self.name = name
        self.aliases = aliases
    }

    static let defaults: [ExpenseCategory] = [
        ExpenseCategory(name: "餐饮", aliases: ["餐饮", "吃饭", "午饭", "晚饭", "早餐", "宵夜", "咖啡", "奶茶"]),
        ExpenseCategory(name: "交通", aliases: ["交通", "打车", "地铁", "公交", "高铁", "火车", "机票", "加油", "停车"]),
        ExpenseCategory(name: "购物", aliases: ["购物", "买", "超市", "日用品", "衣服", "鞋子", "网购"]),
        ExpenseCategory(name: "娱乐", aliases: ["娱乐", "电影", "游戏", "唱歌", "旅游", "聚会"]),
        ExpenseCategory(name: "看病", aliases: ["看病", "医院", "挂号", "买药", "药店", "体检", "门诊"])
    ]

    var keywords: [String] {
        Array(Set([name] + aliases)).sorted { $0.count > $1.count }
    }
}
