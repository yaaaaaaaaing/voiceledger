import SwiftUI

struct VoiceEntryView: View {
    @EnvironmentObject private var store: ExpenseStore
    @EnvironmentObject private var categoryStore: CategoryStore
    @StateObject private var speechService = SpeechRecognizerService()

    @State private var parseResult: VoiceParseResult?
    @State private var parseError: String?
    @State private var isBusy = false
    @State private var editableDetail = ""
    @State private var editableAmount = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    actionCard
                    resultCard
                    hintCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("语音记账")
            .task {
                await speechService.requestPermissions()
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支持大类")
                .font(.headline)
            Text(categoryStore.displayNames())
                .font(.body)
                .foregroundStyle(.secondary)
            if let error = speechService.authorizationError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actionCard: some View {
        VStack(spacing: 16) {
            Button {
                toggleRecording()
            } label: {
                Label(
                    speechService.isRecording ? "停止录音" : "开始录音",
                    systemImage: speechService.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                )
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(speechService.isRecording ? .red : .orange)

            VStack(alignment: .leading, spacing: 8) {
                Text("识别结果")
                    .font(.subheadline.weight(.semibold))
                Text(speechService.transcript.isEmpty ? "点击开始录音后，说一句完整的话，例如：餐饮 午饭 35元" : speechService.transcript)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button("识别内容") {
                parseTranscript()
            }
            .buttonStyle(.bordered)
            .disabled(speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isBusy)

            if parseResult != nil {
                Button("保存当前记录") {
                    saveParsedEntry()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("解析结果")
                .font(.headline)

            if let parseResult {
                LabeledContent("大类", value: parseResult.category.name)
                VStack(alignment: .leading, spacing: 6) {
                    Text("子信息")
                        .font(.subheadline.weight(.semibold))
                    TextField("例如：午饭", text: $editableDetail)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("金额")
                        .font(.subheadline.weight(.semibold))
                    TextField("例如：35.5", text: $editableAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    Text("识别金额：\(CurrencyFormatter.string(from: parseResult.amount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let parseError {
                Text(parseError)
                    .foregroundStyle(.red)
            } else {
                Text("还没有解析记录。")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var hintCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("推荐说法")
                .font(.headline)
            Text("餐饮 午饭 35元")
            Text("交通 打车 18块")
            Text("购物 超市 126元")
            Text("娱乐 电影票 49元")
            Text("看病 买药 28元")
            Text("识别后你还可以手工修改子项目和金额，再保存。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
            return
        }

        do {
            try speechService.startRecording()
            parseResult = nil
            parseError = nil
            editableDetail = ""
            editableAmount = ""
        } catch {
            parseError = error.localizedDescription
        }
    }

    private func parseTranscript() {
        isBusy = true
        defer { isBusy = false }

        do {
            let result = try ExpenseParser.parse(text: speechService.transcript, categories: categoryStore.categories)
            parseResult = result
            parseError = nil
            editableDetail = result.detail
            editableAmount = decimalText(from: result.amount)
        } catch {
            parseResult = nil
            parseError = error.localizedDescription
        }
    }

    private func saveParsedEntry() {
        guard var result = parseResult else { return }
        let trimmedDetail = editableDetail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDetail.isEmpty else {
            parseError = "子项目不能为空。"
            return
        }
        guard let amount = Decimal(string: editableAmount.trimmingCharacters(in: .whitespacesAndNewlines)), amount > 0 else {
            parseError = "请输入正确金额，例如 35 或 35.5。"
            return
        }

        result.detail = trimmedDetail
        result.amount = amount
        parseResult = result
        store.add(result.entry)
        parseError = nil
        speechService.transcript = ""
        editableDetail = ""
        editableAmount = ""
        parseResult = nil
    }

    private func decimalText(from amount: Decimal) -> String {
        NSDecimalNumber(decimal: amount).stringValue
    }
}
