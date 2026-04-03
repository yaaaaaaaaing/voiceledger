import SwiftUI

struct CategoryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var categoryStore: CategoryStore

    let category: ExpenseCategory?

    @State private var name: String
    @State private var aliases: String

    init(category: ExpenseCategory? = nil) {
        self.category = category
        _name = State(initialValue: category?.name ?? "")
        _aliases = State(initialValue: category?.aliases.joined(separator: ",") ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("分类信息") {
                    TextField("分类名称", text: $name)
                    TextField("别名，用英文逗号分隔", text: $aliases)
                }
            }
            .navigationTitle(category == nil ? "新增分类" : "编辑分类")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                }
            }
        }
    }

    private func save() {
        if let category {
            categoryStore.updateCategory(id: category.id, name: name, aliasesText: aliases)
        } else {
            categoryStore.addCategory(name: name, aliasesText: aliases)
        }
        dismiss()
    }
}
