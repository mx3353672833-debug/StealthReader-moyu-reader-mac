import Foundation

enum BookFormat: String, Codable {
    case txt
    case epub

    static func from(fileExtension: String) -> BookFormat? {
        switch fileExtension.lowercased() {
        case "txt": return .txt
        case "epub": return .epub
        default: return nil
        }
    }
}
