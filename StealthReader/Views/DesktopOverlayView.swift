import SwiftUI

struct DesktopOverlayView: View {
    @ObservedObject var reader: ReaderService
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: reader.previous) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10))
                    .foregroundColor(reader.textColor.opacity(reader.textOpacity))
            }
            .buttonStyle(.borderless)
            .opacity(isHovering ? 1 : 0)
            .disabled(!reader.canGoPrevious)

            Text(reader.currentText)
                .font(.system(size: reader.fontSize, weight: .light, design: .monospaced))
                .foregroundColor(reader.textColor.opacity(reader.textOpacity))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: reader.next) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(reader.textColor.opacity(reader.textOpacity))
            }
            .buttonStyle(.borderless)
            .opacity(isHovering ? 1 : 0)
            .disabled(!reader.canGoNext)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(reader.bgColor.opacity(reader.bgOpacity))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
