import SwiftUI

struct MenuBarView: View {
    @ObservedObject var reader: ReaderService
    @State private var showSettings = false
    @State private var recordingPrev = false
    @State private var recordingNext = false

    var body: some View {
        Group {
            if reader.showLibrary {
                LibraryView(reader: reader)
            } else {
                mainMenu
            }
        }
        .background(KeyEventHandling(recordingPrev: $recordingPrev, recordingNext: $recordingNext, reader: reader))
    }

    private var mainMenu: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current text display
            Text(reader.currentText)
                .font(.system(size: 13))
                .lineLimit(3)
                .frame(maxWidth: 300, alignment: .leading)
                .padding(.vertical, 4)

            Divider()

            // Progress
            if reader.currentBook != nil {
                HStack {
                    Text(reader.progressText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }

            // Navigation
            HStack(spacing: 12) {
                Button(action: reader.previous) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!reader.canGoPrevious)
                .buttonStyle(.borderless)

                Button(action: reader.next) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!reader.canGoNext)
                .buttonStyle(.borderless)

                Spacer()

                Button("回到开头") {
                    reader.goToStart()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding(.horizontal, 4)

            Divider()

            // Mode toggle
            Button(action: { reader.toggleDesktopMode() }) {
                HStack {
                    Image(systemName: reader.isDesktopVisible ? "eye.slash" : "eye")
                    Text(reader.isDesktopVisible ? "隐藏桌面" : "显示桌面")
                }
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 4)

            // Settings toggle
            Button(action: { showSettings.toggle() }) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("悬浮窗设置")
                }
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 4)

            if showSettings {
                settingsPanel
            }

            // Open file & library
            HStack {
                Button("打开文件...") {
                    reader.openFile()
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(action: { reader.showLibrary = true }) {
                    HStack {
                        Image(systemName: "books.vertical")
                        Text("书库")
                    }
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding(.horizontal, 4)

            if let error = reader.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }

            Divider()

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 4)
        }
        .padding(8)
        .frame(width: 300)
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Chars per page
            HStack {
                Text("每页字数")
                    .font(.caption)
                    .frame(width: 60, alignment: .leading)
                Slider(value: Binding(
                    get: { Double(reader.charsPerPage) },
                    set: { reader.charsPerPage = Int($0) }
                ), in: 20...200, step: 5)
                Text("\(reader.charsPerPage)")
                    .font(.caption)
                    .frame(width: 30)
            }

            // Font size
            HStack {
                Text("字号")
                    .font(.caption)
                    .frame(width: 60, alignment: .leading)
                Slider(value: $reader.fontSize, in: 8...24, step: 1)
                Text(String(format: "%.0f", reader.fontSize))
                    .font(.caption)
                    .frame(width: 30)
            }

            // Background opacity
            HStack {
                Text("背景透明")
                    .font(.caption)
                    .frame(width: 60, alignment: .leading)
                Slider(value: $reader.bgOpacity, in: 0...1, step: 0.05)
                Text(String(format: "%.0f%%", reader.bgOpacity * 100))
                    .font(.caption)
                    .frame(width: 35)
            }

            // Text opacity
            HStack {
                Text("文字透明")
                    .font(.caption)
                    .frame(width: 60, alignment: .leading)
                Slider(value: $reader.textOpacity, in: 0.1...1, step: 0.05)
                Text(String(format: "%.0f%%", reader.textOpacity * 100))
                    .font(.caption)
                    .frame(width: 35)
            }

            // Colors
            HStack {
                Text("背景色")
                    .font(.caption)
                    .frame(width: 60, alignment: .leading)
                ColorPicker("", selection: $reader.bgColor).labelsHidden()
                Spacer()
                Text("文字色")
                    .font(.caption)
                ColorPicker("", selection: $reader.textColor).labelsHidden()
            }

            Divider()

            // Keyboard shortcuts
            Text("快捷键设置")
                .font(.caption)
                .fontWeight(.medium)

            HStack {
                Text("上一页")
                    .font(.caption)
                    .frame(width: 60, alignment: .leading)
                Button(action: {
                    recordingPrev.toggle()
                    recordingNext = false
                }) {
                    Text(ReaderService.keyDisplayName(keyCode: reader.prevKey.0, mods: reader.prevKey.1))
                        .font(.system(size: 11, design: .monospaced))
                        .frame(minWidth: 80)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 3).fill(recordingPrev ? Color.accentColor : Color.gray.opacity(0.2)))
                        .foregroundColor(recordingPrev ? .white : .primary)
                }
                .buttonStyle(.borderless)

                if recordingPrev {
                    Text("请按键...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text("下一页")
                    .font(.caption)
                    .frame(width: 60, alignment: .leading)
                Button(action: {
                    recordingNext.toggle()
                    recordingPrev = false
                }) {
                    Text(ReaderService.keyDisplayName(keyCode: reader.nextKey.0, mods: reader.nextKey.1))
                        .font(.system(size: 11, design: .monospaced))
                        .frame(minWidth: 80)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 3).fill(recordingNext ? Color.accentColor : Color.gray.opacity(0.2)))
                        .foregroundColor(recordingNext ? .white : .primary)
                }
                .buttonStyle(.borderless)

                if recordingNext {
                    Text("请按键...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Nav panel toggle
            Toggle(isOn: $reader.showNavPanel) {
                HStack {
                    Image(systemName: "rectangle.split.2x1")
                    Text("独立翻页面板")
                }
                .font(.caption)
            }
            .toggleStyle(.checkbox)

            if reader.showNavPanel {
                HStack {
                    Text("面板透明")
                        .font(.caption)
                        .frame(width: 60, alignment: .leading)
                    Slider(value: $reader.navBgOpacity, in: 0...1, step: 0.05)
                    Text(String(format: "%.0f%%", reader.navBgOpacity * 100))
                        .font(.caption)
                        .frame(width: 35)
                }
                HStack {
                    Text("面板色")
                        .font(.caption)
                        .frame(width: 60, alignment: .leading)
                    ColorPicker("", selection: $reader.navBgColor).labelsHidden()
                }
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.15)))
        .padding(.horizontal, 4)
    }
}

// NSViewRepresentable to capture key events for shortcut recording
struct KeyEventHandling: NSViewRepresentable {
    @Binding var recordingPrev: Bool
    @Binding var recordingNext: Bool
    let reader: ReaderService

    func makeCoordinator() -> Coordinator {
        Coordinator(reader: reader, recordingPrev: $recordingPrev, recordingNext: $recordingNext)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let shouldRecord = recordingPrev || recordingNext
        if shouldRecord && context.coordinator.monitor == nil {
            context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if self.recordingPrev {
                    reader.prevKey = (event.keyCode, event.modifierFlags.intersection(.deviceIndependentFlagsMask))
                    recordingPrev = false
                    context.coordinator.removeMonitor()
                    return nil
                }
                if self.recordingNext {
                    reader.nextKey = (event.keyCode, event.modifierFlags.intersection(.deviceIndependentFlagsMask))
                    recordingNext = false
                    context.coordinator.removeMonitor()
                    return nil
                }
                return event
            }
        } else if !shouldRecord {
            context.coordinator.removeMonitor()
        }
    }

    class Coordinator {
        var monitor: Any?
        let reader: ReaderService
        @Binding var recordingPrev: Bool
        @Binding var recordingNext: Bool

        init(reader: ReaderService, recordingPrev: Binding<Bool>, recordingNext: Binding<Bool>) {
            self.reader = reader
            self._recordingPrev = recordingPrev
            self._recordingNext = recordingNext
        }

        func removeMonitor() {
            if let m = monitor {
                NSEvent.removeMonitor(m)
                monitor = nil
            }
        }
    }
}
