import Combine
import Foundation

@MainActor
final class CategoryStore: ObservableObject {
    @Published private(set) var categories: [ExpenseCategory] = []

    private let fileManager: FileManager
    private let saveURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.saveURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("categories.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    func addCategory(name: String, aliasesText: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let aliases = parseAliases(from: aliasesText, fallbackName: trimmedName)
        categories.append(ExpenseCategory(name: trimmedName, aliases: aliases))
        categories.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        save()
    }

    func updateCategory(id: UUID, name: String, aliasesText: String) {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        categories[index].name = trimmedName
        categories[index].aliases = parseAliases(from: aliasesText, fallbackName: trimmedName)
        categories.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        save()
    }

    func delete(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
        save()
    }

    func displayNames() -> String {
        categories.map(\.name).joined(separator: " / ")
    }

    private func parseAliases(from text: String, fallbackName: String) -> [String] {
        let values = text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let merged = Array(Set(values + [fallbackName]))
        return merged.sorted { $0.count > $1.count }
    }

    private func load() {
        guard fileManager.fileExists(atPath: saveURL.path) else {
            categories = ExpenseCategory.defaults
            save()
            return
        }

        do {
            let data = try Data(contentsOf: saveURL)
            categories = try decoder.decode([ExpenseCategory].self, from: data)
            if categories.isEmpty {
                categories = ExpenseCategory.defaults
                save()
            }
        } catch {
            categories = ExpenseCategory.defaults
            save()
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(categories)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            assertionFailure("Failed to save categories: \(error)")
        }
    }
}
