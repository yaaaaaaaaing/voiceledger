import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: ExpenseStore

    var body: some View {
        NavigationStack {
            List {
                if store.entries.isEmpty {
                    Text("还没有历史记录。")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.entries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(entry.category.rawValue)
                                    .font(.headline)
                                Spacer()
                                Text(CurrencyFormatter.string(from: entry.amount))
                                    .font(.headline)
                            }
                            Text(entry.detail)
                                .foregroundStyle(.secondary)
                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: store.delete)
                }
            }
            .navigationTitle("历史记录")
            .toolbar {
                EditButton()
            }
        }
    }
}
