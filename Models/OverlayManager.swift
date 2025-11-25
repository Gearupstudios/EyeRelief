import SwiftUI
import AppKit

class OverlayManager: ObservableObject {
    private var overlayWindow: NSWindow?
    private var onComplete: (() -> Void)?
    private var isClosing = false

    func showBreakOverlay(onComplete: @escaping () -> Void) {
        guard overlayWindow == nil, !isClosing else { return }

        self.onComplete = onComplete

        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let screenFrame = screen.frame

        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.acceptsMouseMovedEvents = true

        let overlayView = BreakOverlayView(onBreakComplete: { [weak self] in
            self?.hideBreakOverlay()
        })

        window.contentView = NSHostingView(rootView: overlayView)
        overlayWindow = window
        window.makeKeyAndOrderFront(nil)
        window.setFrame(screenFrame, display: true)

        NSApp.activate(ignoringOtherApps: true)
    }

    func hideBreakOverlay() {
        guard !isClosing else { return }
        isClosing = true

        // Capture completion handler before cleanup
        let completion = onComplete
        onComplete = nil

        // Fade out and close window safely
        if let window = overlayWindow {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                window.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                window.orderOut(nil)
                window.contentView = nil
                self?.overlayWindow = nil
                self?.isClosing = false

                // Call completion on next run loop to ensure cleanup is done
                DispatchQueue.main.async {
                    completion?()
                }
            })
        } else {
            isClosing = false
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    var isOverlayVisible: Bool {
        return overlayWindow != nil && !isClosing
    }
}