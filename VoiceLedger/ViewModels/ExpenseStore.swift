import Combine
import Foundation

@MainActor
final class ExpenseStore: ObservableObject {
    @Published private(set) var entries: [ExpenseEntry] = []

    private let fileManager: FileManager
    private let saveURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.saveURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("expenses.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        load()
    }

    func add(_ entry: ExpenseEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func entries(for month: Date) -> [ExpenseEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.createdAt, equalTo: month, toGranularity: .month) }
    }

    func monthlyTotal(for month: Date) -> Decimal {
        entries(for: month).reduce(0) { $0 + $1.amount }
    }

    func monthlySummary(for month: Date) -> [(category: String, total: Decimal)] {
        let grouped = Dictionary(grouping: entries(for: month), by: \.categoryName)
        return grouped.keys.sorted().compactMap { category in
            let total = grouped[category, default: []].reduce(0) { $0 + $1.amount }
            guard total > 0 else { return nil }
            return (category, total)
        }
    }

    func monthlyEntries(for month: Date, categoryName: String) -> [ExpenseEntry] {
        entries(for: month)
            .filter { $0.categoryName == categoryName }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func updateEntry(id: UUID, detail: String, amount: Decimal) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].detail = detail
        entries[index].amount = amount
        save()
    }

    private func load() {
        guard fileManager.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            entries = try decoder.decode([ExpenseEntry].self, from: data)
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            entries = []
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(entries)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            assertionFailure("Failed to save entries: \(error)")
        }
    }
}
