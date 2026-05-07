import Foundation

struct TXTParser {
    static func parse(filePath: String) throws -> [String] {
        let url = URL(fileURLWithPath: filePath)
        let content = try String(contentsOf: url, encoding: .utf8)

        // Split by double newline for paragraphs, fallback to single lines
        let paragraphs = content
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if paragraphs.count > 1 {
            return paragraphs
        }

        // Fallback: split by single newlines
        return content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
