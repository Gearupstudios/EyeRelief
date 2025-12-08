import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval = 20 * 60 // Default to 20 minutes
    @Published var isActive: Bool = false
    @Published var selectedDurationIndex: Int = 1  // Default to 20 min (index 1)
    @Published var isShowingOverlay: Bool = false
    @Published var sessionBreakCount: Int = 0  // Tracks breaks in current session (0-10)
    @Published var isPausedBySchedule: Bool = false  // Indicates if paused due to smart scheduling

    private var timer: Timer?
    private var scheduleCheckTimer: Timer?
    private let notificationManager = NotificationManager()
    private let overlayManager = OverlayManager()
    private let statsManager = StatsManager.shared
    private let scheduleManager = ScheduleManager.shared

    static let maxSessionBreaks: Int = 10  // Maximum breaks to track in outer ring

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

        // Start periodic schedule checking
        startScheduleChecking()
    }

    // MARK: - Schedule Checking

    private func startScheduleChecking() {
        // Check schedule every 30 seconds
        scheduleCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkScheduleAndAdjust()
        }
    }

    private func checkScheduleAndAdjust() {
        let shouldPause = scheduleManager.shouldPauseTimer()

        if shouldPause && isActive && !isPausedBySchedule {
            // Need to pause due to schedule
            print("⏸️ Pausing timer: \(scheduleManager.pauseReason)")
            isPausedBySchedule = true
            pauseTimerInternal()
        } else if !shouldPause && isPausedBySchedule {
            // Schedule cleared, can resume
            print("▶️ Schedule cleared, resuming timer")
            isPausedBySchedule = false
            startTimerInternal()
        }
    }

    // MARK: - Timer Control

    func startTimer() {
        // Check if schedule allows starting
        if scheduleManager.shouldPauseTimer() {
            print("⏸️ Cannot start timer: \(scheduleManager.pauseReason)")
            isPausedBySchedule = true
            return
        }

        // Request notification permissions on first timer start
        notificationManager.requestPermission()
        isPausedBySchedule = false
        startTimerInternal()
    }

    private func startTimerInternal() {
        print("▶️ Starting timer with \(timeRemaining) seconds remaining")
        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Check schedule mid-timer
            if self.scheduleManager.smartSchedulingEnabled && self.scheduleManager.shouldPauseTimer() {
                if !self.isPausedBySchedule {
                    print("⏸️ Pausing timer mid-run: \(self.scheduleManager.pauseReason)")
                    self.isPausedBySchedule = true
                    self.pauseTimerInternal()
                }
                return
            }

            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                if Int(self.timeRemaining) % 60 == 0 || self.timeRemaining < 5 {
                    print("⏰ Time remaining: \(Int(self.timeRemaining)) seconds")
                }
            } else {
                print("⏰ Timer reached ZERO!")
                self.timerReachedZero()
            }
        }
    }

    func pauseTimer() {
        isPausedBySchedule = false
        pauseTimerInternal()
    }

    private func pauseTimerInternal() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }

    func resetTimer() {
        pauseTimerInternal()
        isPausedBySchedule = false
        timeRemaining = timerDurations[selectedDurationIndex]
    }

    func selectDuration(at index: Int) {
        guard index >= 0 && index < timerDurations.count else { return }
        selectedDurationIndex = index
        let wasActive = isActive
        pauseTimerInternal()
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

            // Increment session break count (cycles back after reaching max)
            self.sessionBreakCount = min(self.sessionBreakCount + 1, TimerManager.maxSessionBreaks)
            print("👁 Session break count: \(self.sessionBreakCount)/\(TimerManager.maxSessionBreaks)")

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

    var scheduleStatusText: String {
        if isPausedBySchedule {
            return scheduleManager.pauseReason
        }
        return ""
    }

    deinit {
        scheduleCheckTimer?.invalidate()
    }
}
