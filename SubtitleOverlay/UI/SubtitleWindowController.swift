import AppKit
import SwiftUI
import Combine

final class SubtitleWindowController: NSObject {

    private var panel: NSPanel?
    private var hostingView: NSHostingView<SubtitlePanelView>?
    private var sizeObserver: AnyCancellable?

    private let minWidth: CGFloat = 300
    private let maxWidth: CGFloat = 900

    func show() {
        if panel == nil {
            createPanel()
        }
        panel?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func toggle() {
        guard let panel else { show(); return }
        panel.isVisible ? hide() : show()
    }

    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 80),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.ignoresMouseEvents = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden

        let hostingView = NSHostingView(rootView: SubtitlePanelView())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = hostingView
        self.hostingView = hostingView
        self.panel = panel

        centerPanel(width: 600, height: 80)

        // Observe content changes to auto-resize.
        sizeObserver = SpeechRecognizer.shared.$segments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.sizeToFit()
            }
    }

    private func sizeToFit() {
        guard let panel, let hostingView else { return }

        hostingView.layoutSubtreeIfNeeded()

        let targetWidth = min(maxWidth, max(minWidth, hostingView.intrinsicContentSize.width))
        let fitSize = hostingView.fittingSize
        let newHeight = max(60, fitSize.height)

        let currentFrame = panel.frame
        let heightDelta = newHeight - currentFrame.height

        let newFrame = NSRect(
            x: currentFrame.minX,
            y: currentFrame.minY - heightDelta,
            width: targetWidth,
            height: newHeight
        )

        panel.setFrame(newFrame, display: true, animate: true)
    }

    private func centerPanel(width: CGFloat, height: CGFloat) {
        guard let panel, let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - width / 2
        let y = screenFrame.minY + 80
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
}
