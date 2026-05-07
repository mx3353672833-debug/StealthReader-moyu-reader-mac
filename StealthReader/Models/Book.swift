import Foundation

struct Book: Codable, Identifiable {
    let id: UUID
    let filePath: String
    let fileName: String
    let format: BookFormat
    let paragraphs: [String]

    init(filePath: String, format: BookFormat, paragraphs: [String]) {
        self.id = UUID()
        self.filePath = filePath
        self.fileName = URL(fileURLWithPath: filePath).lastPathComponent
        self.format = format
        self.paragraphs = paragraphs
    }

    var totalParagraphs: Int {
        paragraphs.count
    }
}
