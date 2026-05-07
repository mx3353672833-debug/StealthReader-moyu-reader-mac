import Foundation

struct LibraryEntry: Codable, Identifiable {
    var id: String { filePath }
    let filePath: String
    let fileName: String
    var lastReadDate: Date
    var charIndex: Int

    init(filePath: String, fileName: String, charIndex: Int = 0) {
        self.filePath = filePath
        self.fileName = fileName
        self.lastReadDate = Date()
        self.charIndex = charIndex
    }
}

class BookLibrary {
    private let key = "bookLibrary"
    private(set) var entries: [LibraryEntry] = []

    init() {
        load()
    }

    func addOrUpdate(filePath: String, fileName: String, charIndex: Int) {
        if let idx = entries.firstIndex(where: { $0.filePath == filePath }) {
            entries[idx].charIndex = charIndex
            entries[idx].lastReadDate = Date()
        } else {
            entries.append(LibraryEntry(filePath: filePath, fileName: fileName, charIndex: charIndex))
        }
        save()
    }

    func remove(filePath: String) {
        entries.removeAll { $0.filePath == filePath }
        save()
    }

    func getEntry(filePath: String) -> LibraryEntry? {
        entries.first { $0.filePath == filePath }
    }

    var sortedEntries: [LibraryEntry] {
        entries.sorted { $0.lastReadDate > $1.lastReadDate }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let loaded = try? JSONDecoder().decode([LibraryEntry].self, from: data) else { return }
        entries = loaded
    }
}
