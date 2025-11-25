import SwiftUI
import AppKit
import Combine

class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    private weak var timerManager: TimerManager?

    func setup(with timerManager: TimerManager) {
        self.timerManager = timerManager

        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "EyeRelief")
            button.action = #selector(togglePopover)
            button.target = self
            updateTitle(timeRemaining: timerManager.timeRemaining, isActive: timerManager.isActive)
        }

        // Subscribe to timer updates
        timerManager.$timeRemaining
            .combineLatest(timerManager.$isActive)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time, isActive in
                self?.updateTitle(timeRemaining: time, isActive: isActive)
            }
            .store(in: &cancellables)
    }

    private func updateTitle(timeRemaining: TimeInterval, isActive: Bool) {
        guard let button = statusItem?.button else { return }

        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)

        if isActive {
            button.title = " \(timeString)"
            button.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "EyeRelief Active")
            button.contentTintColor = NSColor.systemGreen
        } else {
            button.title = ""
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "EyeRelief Paused")
            button.contentTintColor = nil
        }
    }

    @objc private func togglePopover() {
        if let window = NSApp.windows.first(where: { $0.title == "EyeRelief" || $0.contentView?.subviews.first is NSHostingView<ContentView> }) {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showInMenuBar(_ show: Bool) {
        statusItem?.isVisible = show
    }
}
