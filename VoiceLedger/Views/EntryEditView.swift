import SwiftUI

struct EntryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: ExpenseStore

    let entry: ExpenseEntry

    @State private var detail: String
    @State private var amountText: String
    @State private var errorMessage: String?

    init(entry: ExpenseEntry) {
        self.entry = entry
        _detail = State(initialValue: entry.detail)
        _amountText = State(initialValue: NSDecimalNumber(decimal: entry.amount).stringValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("账目信息") {
                    LabeledContent("大类", value: entry.categoryName)
                    TextField("子项目", text: $detail)
                    TextField("金额", text: $amountText)
                        .keyboardType(.decimalPad)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("修改记录")
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
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDetail.isEmpty else {
            errorMessage = "子项目不能为空。"
            return
        }
        guard let amount = Decimal(string: amountText.trimmingCharacters(in: .whitespacesAndNewlines)), amount > 0 else {
            errorMessage = "请输入正确金额。"
            return
        }

        store.updateEntry(id: entry.id, detail: trimmedDetail, amount: amount)
        dismiss()
    }
}
