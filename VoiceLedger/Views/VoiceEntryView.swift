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
    @State private var selectedExpenseDate = Date()
    @State private var isPressingRecord = false

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
            ForEach(categoryStore.categories) { category in
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.body.weight(.semibold))
                    Text("别名：\(category.aliases.joined(separator: "、"))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            DatePicker(
                "消费时间",
                selection: $selectedExpenseDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
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
            recordButton

            VStack(alignment: .leading, spacing: 8) {
                Text("识别结果")
                    .font(.subheadline.weight(.semibold))
                Text(speechService.transcript.isEmpty ? "按住“记录”并说一句完整的话，例如：餐饮 午饭 35元" : speechService.transcript)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

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

    private var recordButton: some View {
        Label(
            isPressingRecord || speechService.isRecording ? "松开后识别" : "按住记录",
            systemImage: isPressingRecord || speechService.isRecording ? "waveform.circle.fill" : "mic.circle.fill"
        )
        .font(.title3.bold())
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .foregroundStyle(.white)
        .background(isPressingRecord || speechService.isRecording ? Color.red : Color.orange)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .scaleEffect(isPressingRecord || speechService.isRecording ? 0.98 : 1)
        .animation(.easeInOut(duration: 0.15), value: isPressingRecord || speechService.isRecording)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    beginPressRecordingIfNeeded()
                }
                .onEnded { _ in
                    endPressRecording()
                }
        )
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
            Text("识别后你还可以手工修改子项目和金额，再保存。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func beginPressRecordingIfNeeded() {
        guard !isPressingRecord, !speechService.isRecording else { return }
        isPressingRecord = true
        do {
            try speechService.startRecording()
            parseResult = nil
            parseError = nil
            editableDetail = ""
            editableAmount = ""
        } catch {
            isPressingRecord = false
            parseError = error.localizedDescription
        }
    }

    private func endPressRecording() {
        guard isPressingRecord || speechService.isRecording else { return }
        isPressingRecord = false
        speechService.stopRecording()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            parseTranscript()
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
        store.add(result.entry(createdAt: selectedExpenseDate))
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
