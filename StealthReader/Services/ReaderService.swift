import Foundation
import SwiftUI

enum DisplayMode: String, CaseIterable {
    case menuBar = "菜单栏"
    case desktop = "桌面"
}

class ReaderService: ObservableObject {
    @Published var currentBook: Book?
    @Published var currentIndex: Int = 0
    @Published var displayMode: DisplayMode = .menuBar
    @Published var isDesktopVisible: Bool = false
    @Published var errorMessage: String?

    // Settings
    @Published var charsPerPage: Int {
        didSet { UserDefaults.standard.set(charsPerPage, forKey: charsPerPageKey) }
    }
    @Published var bgColor: Color {
        didSet { saveColor(bgColor, key: bgColorKey) }
    }
    @Published var bgOpacity: Double {
        didSet { UserDefaults.standard.set(bgOpacity, forKey: bgOpacityKey) }
    }
    @Published var textColor: Color {
        didSet { saveColor(textColor, key: textColorKey) }
    }
    @Published var textOpacity: Double {
        didSet { UserDefaults.standard.set(textOpacity, forKey: textOpacityKey) }
    }
    @Published var fontSize: CGFloat {
        didSet { UserDefaults.standard.set(Double(fontSize), forKey: fontSizeKey) }
    }

    // Nav panel
    @Published var showNavPanel: Bool {
        didSet { UserDefaults.standard.set(showNavPanel, forKey: showNavPanelKey) }
    }
    @Published var navBgColor: Color {
        didSet { saveColor(navBgColor, key: navBgColorKey) }
    }
    @Published var navBgOpacity: Double {
        didSet { UserDefaults.standard.set(navBgOpacity, forKey: navBgOpacityKey) }
    }

    // Keyboard shortcuts: (keyCode, modifiers)
    @Published var prevKey: (UInt16, NSEvent.ModifierFlags) {
        didSet {
            UserDefaults.standard.set(prevKey.0, forKey: prevKeyCodeKey)
            UserDefaults.standard.set(prevKey.1.rawValue, forKey: prevKeyModsKey)
        }
    }
    @Published var nextKey: (UInt16, NSEvent.ModifierFlags) {
        didSet {
            UserDefaults.standard.set(nextKey.0, forKey: nextKeyCodeKey)
            UserDefaults.standard.set(nextKey.1.rawValue, forKey: nextKeyModsKey)
        }
    }

    // Library
    let library = BookLibrary()
    @Published var showLibrary: Bool = false

    // Full text as single string, paged by charsPerPage
    private var fullText: String = ""
    private var globalMonitor: Any?
    private var localMonitor: Any?

    private let progressKey = "readingProgress"
    private let modeKey = "displayMode"
    private let charsPerPageKey = "charsPerPage"
    private let bgColorKey = "bgColor"
    private let bgOpacityKey = "bgOpacity"
    private let textColorKey = "textColor"
    private let textOpacityKey = "textOpacity"
    private let fontSizeKey = "fontSize"
    private let showNavPanelKey = "showNavPanel"
    private let navBgColorKey = "navBgColor"
    private let navBgOpacityKey = "navBgOpacity"
    private let prevKeyCodeKey = "prevKeyCode"
    private let prevKeyModsKey = "prevKeyMods"
    private let nextKeyCodeKey = "nextKeyCode"
    private let nextKeyModsKey = "nextKeyMods"

    init() {
        let defaults = UserDefaults.standard
        charsPerPage = defaults.object(forKey: charsPerPageKey) as? Int ?? 60
        bgOpacity = defaults.object(forKey: bgOpacityKey) as? Double ?? 0.7
        textOpacity = defaults.object(forKey: textOpacityKey) as? Double ?? 1.0
        fontSize = CGFloat(defaults.object(forKey: fontSizeKey) as? Double ?? 12.0)
        bgColor = Self.loadColor(key: bgColorKey) ?? .black
        textColor = Self.loadColor(key: textColorKey) ?? .white
        showNavPanel = defaults.object(forKey: showNavPanelKey) as? Bool ?? false
        navBgOpacity = defaults.object(forKey: navBgOpacityKey) as? Double ?? 0.5
        navBgColor = Self.loadColor(key: navBgColorKey) ?? .black

        // Default: Left arrow = prev, Right arrow = next (no modifiers)
        let prevCode = defaults.object(forKey: prevKeyCodeKey) as? UInt16 ?? 123 // left arrow
        let prevModsRaw = defaults.object(forKey: prevKeyModsKey) as? UInt ?? 0
        prevKey = (prevCode, NSEvent.ModifierFlags(rawValue: prevModsRaw))

        let nextCode = defaults.object(forKey: nextKeyCodeKey) as? UInt16 ?? 124 // right arrow
        let nextModsRaw = defaults.object(forKey: nextKeyModsKey) as? UInt ?? 0
        nextKey = (nextCode, NSEvent.ModifierFlags(rawValue: nextModsRaw))

        loadSettings()
        startGlobalKeyMonitor()
        loadLastBook()
    }

    deinit {
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
        if let m = localMonitor { NSEvent.removeMonitor(m) }
    }

    // MARK: - Text & Paging

    var currentText: String {
        guard !fullText.isEmpty else { return "未加载书籍" }
        let start = fullText.index(fullText.startIndex, offsetBy: min(currentIndex, fullText.count - 1))
        let end = fullText.index(start, offsetBy: charsPerPage, limitedBy: fullText.endIndex) ?? fullText.endIndex
        return String(fullText[start..<end])
    }

    var progressText: String {
        guard !fullText.isEmpty else { return "" }
        let page = currentIndex / charsPerPage + 1
        let total = max(1, Int(ceil(Double(fullText.count) / Double(charsPerPage))))
        return "\(page)/\(total)"
    }

    var canGoNext: Bool {
        guard !fullText.isEmpty else { return false }
        return currentIndex + charsPerPage < fullText.count
    }

    var canGoPrevious: Bool {
        return currentIndex > 0
    }

    func next() {
        guard canGoNext else { return }
        currentIndex += charsPerPage
        saveProgress()
    }

    func previous() {
        guard canGoPrevious else { return }
        currentIndex = max(0, currentIndex - charsPerPage)
        saveProgress()
    }

    func goToStart() {
        currentIndex = 0
        saveProgress()
    }

    // MARK: - Global Key Monitor

    private func startGlobalKeyMonitor() {
        // Check accessibility permission (required for global hotkeys)
        if !AXIsProcessTrusted() {
            // Only show system prompt once, not every launch
            let hasPrompted = UserDefaults.standard.bool(forKey: "hasPromptedAccessibility")
            if !hasPrompted {
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
                AXIsProcessTrustedWithOptions(options)
                UserDefaults.standard.set(true, forKey: "hasPromptedAccessibility")
            }
        }

        // Global: captures events when OTHER apps are focused
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        // Local: captures events when THIS app is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let code = event.keyCode
        // Only compare user-facing modifiers (ignore caps lock, fn, numeric pad, etc.)
        let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
        let prevMods = prevKey.1.intersection([.command, .option, .control, .shift])
        let nextMods = nextKey.1.intersection([.command, .option, .control, .shift])

        if code == prevKey.0 && mods == prevMods {
            DispatchQueue.main.async { self.previous() }
        } else if code == nextKey.0 && mods == nextMods {
            DispatchQueue.main.async { self.next() }
        }
    }

    // MARK: - File Loading

    private func loadLastBook() {
        // Try library first, fall back to old ReadingProgress
        let entry = library.sortedEntries.first
        let progress = loadProgress()

        let path: String
        let savedIndex: Int
        if let entry = entry, FileManager.default.fileExists(atPath: entry.filePath) {
            path = entry.filePath
            savedIndex = entry.charIndex
        } else if let progress = progress, FileManager.default.fileExists(atPath: progress.filePath) {
            path = progress.filePath
            savedIndex = progress.paragraphIndex
        } else {
            return
        }

        let ext = URL(fileURLWithPath: path).pathExtension
        guard let format = BookFormat.from(fileExtension: ext) else { return }

        do {
            let paragraphs: [String]
            switch format {
            case .txt:
                paragraphs = try TXTParser.parse(filePath: path)
            case .epub:
                paragraphs = try EPUBParser.parse(filePath: path)
            }

            let book = Book(filePath: path, format: format, paragraphs: paragraphs)
            self.currentBook = book
            self.fullText = paragraphs.joined(separator: "\n")
            self.currentIndex = min(savedIndex, max(0, fullText.count - 1))
            self.errorMessage = nil
        } catch {}
    }

    func openBook(filePath: String) {
        guard FileManager.default.fileExists(atPath: filePath) else {
            errorMessage = "文件不存在: \(filePath)"
            return
        }

        let ext = URL(fileURLWithPath: filePath).pathExtension
        guard let format = BookFormat.from(fileExtension: ext) else {
            errorMessage = "不支持的格式: \(ext)"
            return
        }

        do {
            let paragraphs: [String]
            switch format {
            case .txt:
                paragraphs = try TXTParser.parse(filePath: filePath)
            case .epub:
                paragraphs = try EPUBParser.parse(filePath: filePath)
            }

            let book = Book(filePath: filePath, format: format, paragraphs: paragraphs)
            self.currentBook = book
            self.fullText = paragraphs.joined(separator: "\n")
            self.errorMessage = nil

            // Restore progress from library
            if let entry = library.getEntry(filePath: filePath) {
                self.currentIndex = min(entry.charIndex, max(0, fullText.count - 1))
            } else {
                self.currentIndex = 0
            }

            saveProgress()
            showLibrary = false
        } catch {
            errorMessage = "打开文件失败: \(error.localizedDescription)"
        }
    }

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .init(filenameExtension: "epub")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let ext = url.pathExtension
            guard let format = BookFormat.from(fileExtension: ext) else {
                errorMessage = "不支持的格式: \(ext)"
                return
            }

            let paragraphs: [String]
            switch format {
            case .txt:
                paragraphs = try TXTParser.parse(filePath: url.path)
            case .epub:
                paragraphs = try EPUBParser.parse(filePath: url.path)
            }

            let book = Book(filePath: url.path, format: format, paragraphs: paragraphs)
            self.currentBook = book
            self.fullText = paragraphs.joined(separator: "\n")
            self.currentIndex = 0
            self.errorMessage = nil

            // Restore progress from library
            if let entry = library.getEntry(filePath: url.path) {
                self.currentIndex = min(entry.charIndex, max(0, fullText.count - 1))
            }

            // Add to library
            library.addOrUpdate(filePath: url.path, fileName: book.fileName, charIndex: currentIndex)
            saveProgress()
        } catch {
            errorMessage = "打开文件失败: \(error.localizedDescription)"
        }
    }

    // MARK: - Mode

    func toggleDesktopMode() {
        isDesktopVisible.toggle()
        displayMode = isDesktopVisible ? .desktop : .menuBar
        saveSettings()
    }

    // MARK: - Persistence

    private func saveProgress() {
        guard let book = currentBook else { return }
        // Update library
        library.addOrUpdate(filePath: book.filePath, fileName: book.fileName, charIndex: currentIndex)
        // Legacy save
        let progress = ReadingProgress(filePath: book.filePath, paragraphIndex: currentIndex)
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }

    private func loadProgress() -> ReadingProgress? {
        guard let data = UserDefaults.standard.data(forKey: progressKey) else { return nil }
        return try? JSONDecoder().decode(ReadingProgress.self, from: data)
    }

    private func saveSettings() {
        UserDefaults.standard.set(displayMode.rawValue, forKey: modeKey)
    }

    private func loadSettings() {
        if let modeString = UserDefaults.standard.string(forKey: modeKey),
           let mode = DisplayMode(rawValue: modeString) {
            displayMode = mode
            isDesktopVisible = (mode == .desktop)
        }
    }

    private func saveColor(_ color: Color, key: String) {
        let nsColor = NSColor(color)
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func loadColor(key: String) -> Color? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else { return nil }
        return Color(nsColor: nsColor)
    }

    // MARK: - Key Display

    static func keyDisplayName(keyCode: UInt16, mods: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if mods.contains(.control) { parts.append("⌃") }
        if mods.contains(.option) { parts.append("⌥") }
        if mods.contains(.shift) { parts.append("⇧") }
        if mods.contains(.command) { parts.append("⌘") }
        parts.append(keyName(for: keyCode))
        return parts.joined()
    }

    private static func keyName(for keyCode: UInt16) -> String {
        let names: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 50: "`",
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
            101: "F9", 103: "F11", 109: "F10", 111: "F12",
            118: "F4", 120: "F2", 122: "F1",
            123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        return names[keyCode] ?? "(\(keyCode))"
    }
}
