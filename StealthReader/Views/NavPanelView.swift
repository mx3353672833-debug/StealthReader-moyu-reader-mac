import SwiftUI

struct NavPanelView: View {
    @ObservedObject var reader: ReaderService
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            Button(action: reader.previous) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.borderless)
            .disabled(!reader.canGoPrevious)

            Divider()
                .frame(height: 16)

            Button(action: reader.next) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.borderless)
            .disabled(!reader.canGoNext)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(reader.navBgColor.opacity(reader.navBgOpacity))
        )
    }
}
