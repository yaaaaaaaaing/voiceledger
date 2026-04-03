import SwiftUI

struct CategoryManagementView: View {
    @EnvironmentObject private var categoryStore: CategoryStore
    @State private var editingCategory: ExpenseCategory?
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section("已启用分类") {
                    ForEach(categoryStore.categories) { category in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(category.name)
                                .font(.headline)
                            Text("别名：\(category.aliases.joined(separator: "、"))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = category
                        }
                    }
                    .onDelete(perform: categoryStore.delete)
                }

                Section("说明") {
                    Text("新增或修改分类后，语音识别会按你维护的名称和别名进行匹配。别名请用英文逗号分隔。")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("分类管理")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                CategoryEditorSheet()
            }
            .sheet(item: $editingCategory) { category in
                CategoryEditorSheet(category: category)
            }
        }
    }
}
