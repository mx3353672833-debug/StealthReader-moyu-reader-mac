import Foundation

struct EPUBParser {
    static func parse(filePath: String) throws -> [String] {
        let fileURL = URL(fileURLWithPath: filePath)
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        // Unzip epub
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try unzip(source: fileURL, destination: tempDir)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Find container.xml to locate content.opf
        let containerPath = tempDir
            .appendingPathComponent("META-INF")
            .appendingPathComponent("container.xml")
        let containerData = try Data(contentsOf: containerPath)
        let containerParser = SimpleXMLParser(data: containerData)
        let rootFilePath = try containerParser.findRootFilePath()

        // Parse content.opf to get spine order
        let rootFileURL = tempDir.appendingPathComponent(rootFilePath)
        let opfData = try Data(contentsOf: rootFileURL)
        let opfDir = rootFileURL.deletingLastPathComponent()
        let opfParser = SimpleXMLParser(data: opfData)
        let spineItems = try opfParser.getSpineItems()

        // Extract text from each chapter
        var paragraphs: [String] = []
        for item in spineItems {
            let chapterURL = opfDir.appendingPathComponent(item)
            guard FileManager.default.fileExists(atPath: chapterURL.path) else { continue }
            let chapterData = try Data(contentsOf: chapterURL)
            let chapterText = extractText(from: chapterData)
            let chapterParagraphs = chapterText
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            paragraphs.append(contentsOf: chapterParagraphs)
        }

        return paragraphs
    }

    private static func unzip(source: URL, destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", source.path, "-d", destination.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(domain: "EPUBParser", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to unzip epub"])
        }
    }

    private static func extractText(from xhtmlData: Data) -> String {
        guard let html = String(data: xhtmlData, encoding: .utf8) else { return "" }

        // Simple HTML tag removal
        var text = html
        // Remove script and style tags with content
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>",
                                         with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>",
                                         with: "", options: .regularExpression)
        // Remove HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        // Decode HTML entities
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        // Clean whitespace
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Simple XML parser for EPUB metadata
private class SimpleXMLParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var rootFilePath: String?
    private var spineItems: [String] = []
    private var manifestItems: [String: String] = [:] // id -> href
    private var currentElement: String = ""
    private var currentAttributes: [String: String] = [:]

    init(data: Data) {
        self.data = data
    }

    func findRootFilePath() throws -> String {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        guard let path = rootFilePath else {
            throw NSError(domain: "EPUBParser", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "Could not find root file path"])
        }
        return path
    }

    func getSpineItems() throws -> [String] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        return spineItems.compactMap { manifestItems[$0] }
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        currentAttributes = attributeDict

        if elementName == "rootfile", let path = attributeDict["full-path"] {
            rootFilePath = path
        }

        if elementName == "item", let id = attributeDict["id"],
           let href = attributeDict["href"] {
            manifestItems[id] = href
        }

        if elementName == "itemref", let idref = attributeDict["idref"] {
            spineItems.append(idref)
        }
    }
}
