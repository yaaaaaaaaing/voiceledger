import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: ExpenseStore
    @State private var editingEntry: ExpenseEntry?

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
                                Text(entry.categoryName)
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingEntry = entry
                        }
                    }
                    .onDelete(perform: store.delete)
                }
            }
            .navigationTitle("历史记录")
            .toolbar {
                EditButton()
            }
            .sheet(item: $editingEntry) { entry in
                EntryEditView(entry: entry)
            }
        }
    }
}
