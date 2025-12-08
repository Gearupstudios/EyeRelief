import SwiftUI
import AppKit

class OverlayManager: ObservableObject {
    private var overlayWindows: [NSWindow] = []
    private var onComplete: (() -> Void)?
    private var isClosing = false

    func showBreakOverlay(onComplete: @escaping () -> Void) {
        guard overlayWindows.isEmpty, !isClosing else { return }

        self.onComplete = onComplete

        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        let primaryScreen = NSScreen.main ?? screens[0]

        // Create overlay window for each screen
        for screen in screens {
            let isPrimary = (screen == primaryScreen)
            let window = createOverlayWindow(for: screen, isPrimary: isPrimary)
            overlayWindows.append(window)
        }

        // Bring all windows to front
        for window in overlayWindows {
            window.makeKeyAndOrderFront(nil)
        }

        NSApp.activate(ignoringOtherApps: true)

        print("📺 Created overlay on \(screens.count) screen(s)")
    }

    private func createOverlayWindow(for screen: NSScreen, isPrimary: Bool) -> NSWindow {
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

        if isPrimary {
            // Primary screen gets full interactive overlay with countdown
            let overlayView = BreakOverlayView(onBreakComplete: { [weak self] in
                self?.hideBreakOverlay()
            })
            window.contentView = NSHostingView(rootView: overlayView)
        } else {
            // Secondary screens get a simpler blocking overlay
            let secondaryView = SecondaryScreenOverlayView()
            window.contentView = NSHostingView(rootView: secondaryView)
            window.ignoresMouseEvents = true  // Block but don't need interaction
        }

        window.setFrame(screenFrame, display: true)
        return window
    }

    func hideBreakOverlay() {
        guard !isClosing else { return }
        isClosing = true

        // Capture completion handler before cleanup
        let completion = onComplete
        onComplete = nil

        let windowsToClose = overlayWindows
        overlayWindows = []

        if windowsToClose.isEmpty {
            isClosing = false
            DispatchQueue.main.async {
                completion?()
            }
            return
        }

        // Fade out all windows simultaneously
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            for window in windowsToClose {
                window.animator().alphaValue = 0
            }
        }, completionHandler: { [weak self] in
            // Close all windows
            for window in windowsToClose {
                window.orderOut(nil)
                window.contentView = nil
            }

            self?.isClosing = false
            print("📺 Closed overlay on \(windowsToClose.count) screen(s)")

            // Call completion on next run loop to ensure cleanup is done
            DispatchQueue.main.async {
                completion?()
            }
        })
    }

    var isOverlayVisible: Bool {
        return !overlayWindows.isEmpty && !isClosing
    }
}

// MARK: - Secondary Screen Overlay
// Simple blocking view for non-primary screens
struct SecondaryScreenOverlayView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.9

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.04, green: 0.04, blue: 0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("👁")
                    .font(.system(size: 80))

                Text("Eye Break")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Look away from all screens")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .scaleEffect(scale)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
                scale = 1.0
            }
        }
    }
}
