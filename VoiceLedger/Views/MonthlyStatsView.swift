import SwiftUI

struct MonthlyStatsView: View {
    @EnvironmentObject private var store: ExpenseStore
    @State private var selectedMonth = Date()
    @State private var expandedCategories: Set<String> = []

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
                            DisclosureGroup(
                                isExpanded: binding(for: item.category),
                                content: {
                                    let entries = store.monthlyEntries(for: selectedMonth, categoryName: item.category)
                                    ForEach(entries) { entry in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(entry.detail)
                                                    .font(.subheadline.weight(.semibold))
                                                Spacer()
                                                Text(CurrencyFormatter.string(from: entry.amount))
                                                    .font(.subheadline)
                                            }
                                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                },
                                label: {
                                    HStack {
                                        Text(item.category)
                                        Spacer()
                                        Text(CurrencyFormatter.string(from: item.total))
                                    }
                                }
                            )
                            .animation(.easeInOut(duration: 0.2), value: expandedCategories)
                        }
                    }
                }
            }
            .navigationTitle("月统计")
        }
    }

    private func binding(for category: String) -> Binding<Bool> {
        Binding(
            get: { expandedCategories.contains(category) },
            set: { isExpanded in
                if isExpanded {
                    expandedCategories.insert(category)
                } else {
                    expandedCategories.remove(category)
                }
            }
        )
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
