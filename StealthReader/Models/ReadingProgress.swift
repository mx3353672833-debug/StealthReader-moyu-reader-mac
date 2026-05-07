import Foundation

struct ReadingProgress: Codable {
    var filePath: String
    var paragraphIndex: Int
    var lastReadDate: Date

    init(filePath: String, paragraphIndex: Int) {
        self.filePath = filePath
        self.paragraphIndex = paragraphIndex
        self.lastReadDate = Date()
    }
}
