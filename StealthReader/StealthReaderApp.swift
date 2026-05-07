import SwiftUI
import Combine

@main
struct StealthReaderApp: App {
    @StateObject private var reader = ReaderService()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(reader: reader)
                .onAppear {
                    appDelegate.reader = reader
                    appDelegate.showOverlay()
                }
        } label: {
            Image(systemName: "book.closed")
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var reader: ReaderService?
    private var overlayPanel: NSPanel?
    private var navPanel: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func showOverlay() {
        guard overlayPanel == nil, let reader = reader else { return }

        // Text overlay panel
        let hostingView = NSHostingView(rootView: DesktopOverlayView(reader: reader))
        hostingView.frame = NSRect(x: 0, y: 0, width: 600, height: 32)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 32),
            styleMask: [.nonactivatingPanel, .borderless, .resizable, .closable],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.isRestorable = false
        panel.minSize = NSSize(width: 200, height: 24)
        panel.maxSize = NSSize(width: 2000, height: 80)

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 300
            let y = screenFrame.maxY - 52
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFront(nil)
        overlayPanel = panel

        // Observe showNavPanel changes
        reader.$showNavPanel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                if show {
                    self?.showNavPanel()
                } else {
                    self?.hideNavPanel()
                }
            }
            .store(in: &cancellables)

        // Restore nav panel state
        if reader.showNavPanel {
            showNavPanel()
        }
    }

    private func showNavPanel() {
        guard navPanel == nil, let reader = reader else { return }

        let navView = NSHostingView(rootView: NavPanelView(reader: reader))
        navView.frame = NSRect(x: 0, y: 0, width: 70, height: 32)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 70, height: 32),
            styleMask: [.nonactivatingPanel, .borderless, .resizable, .closable],
            backing: .buffered,
            defer: false
        )

        panel.contentView = navView
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.isRestorable = false
        panel.minSize = NSSize(width: 50, height: 24)
        panel.maxSize = NSSize(width: 300, height: 80)

        // Position at right side of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - 100
            let y = screenFrame.midY
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFront(nil)
        navPanel = panel
    }

    private func hideNavPanel() {
        navPanel?.close()
        navPanel = nil
    }
}
