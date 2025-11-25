import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval = 20 * 60 // Default to 20 minutes
    @Published var isActive: Bool = false
    @Published var selectedDurationIndex: Int = 1  // Default to 20 min (index 1)
    @Published var isShowingOverlay: Bool = false

    private var timer: Timer?
    private let notificationManager = NotificationManager()
    private let overlayManager = OverlayManager()
    private let statsManager = StatsManager.shared

    // Predefined timer durations in seconds
    let timerDurations: [TimeInterval] = [
        15 * 60,  // 15 minutes
        20 * 60,  // 20 minutes
        30 * 60,  // 30 minutes
        45 * 60,  // 45 minutes
        60 * 60   // 1 hour
    ]

    // Display names for timer options
    let timerDurationLabels: [String] = [
        "15 min",
        "20 min",
        "30 min",
        "45 min",
        "1 hour"
    ]

    init() {
        timeRemaining = timerDurations[selectedDurationIndex]
        print("⏱️ TimerManager initialized with \(timeRemaining) seconds (index: \(selectedDurationIndex))")
    }

    func startTimer() {
        // Request notification permissions on first timer start
        notificationManager.requestPermission()

        print("▶️ Starting timer with \(timeRemaining) seconds remaining")
        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                if Int(self.timeRemaining) % 5 == 0 || self.timeRemaining < 5 {
                    print("⏰ Time remaining: \(Int(self.timeRemaining)) seconds")
                }
            } else {
                print("⏰ Timer reached ZERO!")
                self.timerReachedZero()
            }
        }
    }
    
    func pauseTimer() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = timerDurations[selectedDurationIndex]
    }
    
    func selectDuration(at index: Int) {
        guard index >= 0 && index < timerDurations.count else { return }
        selectedDurationIndex = index
        let wasActive = isActive
        pauseTimer()
        timeRemaining = timerDurations[selectedDurationIndex]
        print("🔄 Duration changed to index \(index): \(timerDurationLabels[index]) (\(timeRemaining) seconds)")
        if wasActive {
            startTimer()
        }
    }

    private func timerReachedZero() {
        print("🎯 Timer reached zero! Showing overlay and notification...")

        // Show notification
        notificationManager.showNotification()

        // Show full-screen overlay
        isShowingOverlay = true
        overlayManager.showBreakOverlay { [weak self] in
            guard let self = self else { return }
            print("✅ Break overlay completed")
            self.isShowingOverlay = false

            // Record this break for stats/streak tracking
            self.statsManager.recordBreak()

            // Reset and restart timer after overlay closes
            print("🔄 Resetting and restarting timer...")
            self.resetTimer()
            self.startTimer()
        }
    }
    
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}