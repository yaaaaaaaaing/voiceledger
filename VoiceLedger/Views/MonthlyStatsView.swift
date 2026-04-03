import SwiftUI

struct MonthlyStatsView: View {
    @EnvironmentObject private var store: ExpenseStore
    @State private var selectedMonth = Date()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    monthPicker
                    LabeledContent("本月总支出", value: CurrencyFormatter.string(from: store.monthlyTotal(for: selectedMonth)))
                }

                Section("分类统计") {
                    if store.monthlySummary(for: selectedMonth).isEmpty {
                        Text("这个月还没有记录。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.monthlySummary(for: selectedMonth), id: \.category) { item in
                            HStack {
                                Text(item.category)
                                Spacer()
                                Text(CurrencyFormatter.string(from: item.total))
                            }
                        }
                    }
                }
            }
            .navigationTitle("月统计")
        }
    }

    private var monthPicker: some View {
        DatePicker(
            "选择月份",
            selection: $selectedMonth,
            displayedComponents: [.date]
        )
        .datePickerStyle(.compact)
    }
}
