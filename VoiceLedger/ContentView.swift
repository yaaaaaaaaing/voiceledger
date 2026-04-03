import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            VoiceEntryView()
                .tabItem {
                    Label("语音记账", systemImage: "mic.fill")
                }

            MonthlyStatsView()
                .tabItem {
                    Label("月统计", systemImage: "chart.pie.fill")
                }

            HistoryView()
                .tabItem {
                    Label("历史记录", systemImage: "clock.fill")
                }

            CategoryManagementView()
                .tabItem {
                    Label("分类管理", systemImage: "square.and.pencil")
                }
        }
        .tint(.orange)
    }
}
