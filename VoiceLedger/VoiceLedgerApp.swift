import SwiftUI

@main
struct VoiceLedgerApp: App {
    @StateObject private var store = ExpenseStore()
    @StateObject private var categoryStore = CategoryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(categoryStore)
        }
    }
}
