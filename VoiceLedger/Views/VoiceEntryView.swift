import SwiftUI

struct VoiceEntryView: View {
    @EnvironmentObject private var store: ExpenseStore
    @StateObject private var speechService = SpeechRecognizerService()

    @State private var parseResult: VoiceParseResult?
    @State private var parseError: String?
    @State private var isBusy = false

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
            Text(ExpenseCategory.allCases.map(\.rawValue).joined(separator: " / "))
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

            Button("识别并保存") {
                saveFromTranscript()
            }
            .buttonStyle(.bordered)
            .disabled(speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isBusy)
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
                LabeledContent("大类", value: parseResult.category.rawValue)
                LabeledContent("子信息", value: parseResult.detail)
                LabeledContent("金额", value: CurrencyFormatter.string(from: parseResult.amount))
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
        } catch {
            parseError = error.localizedDescription
        }
    }

    private func saveFromTranscript() {
        isBusy = true
        defer { isBusy = false }

        do {
            let result = try ExpenseParser.parse(text: speechService.transcript)
            parseResult = result
            parseError = nil
            store.add(result.entry)
            speechService.transcript = ""
        } catch {
            parseResult = nil
            parseError = error.localizedDescription
        }
    }
}
