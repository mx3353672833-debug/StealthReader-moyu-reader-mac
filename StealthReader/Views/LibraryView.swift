import SwiftUI

struct LibraryView: View {
    @ObservedObject var reader: ReaderService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("书库")
                    .font(.headline)
                Spacer()
                Button(action: { reader.showLibrary = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if reader.library.sortedEntries.isEmpty {
                VStack {
                    Spacer()
                    Text("还没有书\n打开一本书开始阅读吧")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(reader.library.sortedEntries) { entry in
                            BookRow(entry: entry, reader: reader)
                            Divider().padding(.horizontal, 12)
                        }
                    }
                }
            }
        }
        .frame(width: 320, height: 400)
    }
}

struct BookRow: View {
    let entry: LibraryEntry
    @ObservedObject var reader: ReaderService
    @State private var isHovering = false

    var body: some View {
        Button(action: { reader.openBook(filePath: entry.filePath) }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.fileName)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text(progressText)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(dateText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(isHovering ? 1 : 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.borderless)
        .onHover { isHovering = $0 }

        // Delete button on hover
        .contextMenu {
            Button("从书库移除", role: .destructive) {
                reader.library.remove(filePath: entry.filePath)
            }
        }
    }

    private var progressText: String {
        guard let book = reader.currentBook, book.filePath == entry.filePath else {
            // Not currently open, calculate from saved charIndex
            return ""
        }
        let page = entry.charIndex / reader.charsPerPage + 1
        return "第\(page)页"
    }

    private var dateText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: entry.lastReadDate, relativeTo: Date())
    }
}
