import Foundation
import AppKit
import EventKit

class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()

    // MARK: - Published Settings
    @Published var smartSchedulingEnabled: Bool {
        didSet { UserDefaults.standard.set(smartSchedulingEnabled, forKey: "smartSchedulingEnabled") }
    }

    @Published var pauseDuringFocusMode: Bool {
        didSet { UserDefaults.standard.set(pauseDuringFocusMode, forKey: "pauseDuringFocusMode") }
    }

    @Published var pauseDuringMeetings: Bool {
        didSet { UserDefaults.standard.set(pauseDuringMeetings, forKey: "pauseDuringMeetings") }
    }

    @Published var activeHoursEnabled: Bool {
        didSet { UserDefaults.standard.set(activeHoursEnabled, forKey: "activeHoursEnabled") }
    }

    @Published var activeHoursStart: Int {  // Hour in 24h format (0-23)
        didSet { UserDefaults.standard.set(activeHoursStart, forKey: "activeHoursStart") }
    }

    @Published var activeHoursEnd: Int {  // Hour in 24h format (0-23)
        didSet { UserDefaults.standard.set(activeHoursEnd, forKey: "activeHoursEnd") }
    }

    // MARK: - Calendar Access
    private let eventStore = EKEventStore()
    @Published var calendarAccessGranted: Bool = false

    // MARK: - Current State
    @Published var isPausedBySchedule: Bool = false
    @Published var pauseReason: String = ""

    init() {
        // Load saved settings
        self.smartSchedulingEnabled = UserDefaults.standard.object(forKey: "smartSchedulingEnabled") as? Bool ?? false
        self.pauseDuringFocusMode = UserDefaults.standard.object(forKey: "pauseDuringFocusMode") as? Bool ?? true
        self.pauseDuringMeetings = UserDefaults.standard.object(forKey: "pauseDuringMeetings") as? Bool ?? true
        self.activeHoursEnabled = UserDefaults.standard.object(forKey: "activeHoursEnabled") as? Bool ?? false
        self.activeHoursStart = UserDefaults.standard.object(forKey: "activeHoursStart") as? Int ?? 9  // 9 AM
        self.activeHoursEnd = UserDefaults.standard.object(forKey: "activeHoursEnd") as? Int ?? 18     // 6 PM

        // Check calendar access status
        checkCalendarAccess()

        // Set up Focus Mode observer
        setupFocusModeObserver()
    }

    // MARK: - Calendar Access

    func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.calendarAccessGranted = granted
                if let error = error {
                    print("❌ Calendar access error: \(error.localizedDescription)")
                } else if granted {
                    print("✅ Calendar access granted")
                }
            }
        }
    }

    private func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            calendarAccessGranted = true
        default:
            calendarAccessGranted = false
        }
    }

    // MARK: - Focus Mode Detection

    private func setupFocusModeObserver() {
        // Observe Do Not Disturb / Focus Mode changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(focusModeChanged),
            name: NSNotification.Name("com.apple.notificationcenterui.dndStateChanged"),
            object: nil
        )
    }

    @objc private func focusModeChanged() {
        DispatchQueue.main.async {
            self.updateScheduleStatus()
        }
    }

    func isFocusModeActive() -> Bool {
        // Check for fullscreen windows which might indicate presentation mode
        for window in NSApp.windows {
            if window.styleMask.contains(.fullScreen) {
                return true
            }
        }

        // Check NSWorkspace for screen saver or screen locked
        if NSWorkspace.shared.frontmostApplication?.localizedName == "ScreenSaverEngine" {
            return true
        }

        return false
    }

    // MARK: - Active Hours Check

    func isWithinActiveHours() -> Bool {
        guard activeHoursEnabled else { return true }  // If disabled, always active

        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // Handle overnight schedules (e.g., 22:00 - 06:00)
        if activeHoursStart <= activeHoursEnd {
            // Normal schedule (e.g., 9:00 - 18:00)
            return currentHour >= activeHoursStart && currentHour < activeHoursEnd
        } else {
            // Overnight schedule (e.g., 22:00 - 06:00)
            return currentHour >= activeHoursStart || currentHour < activeHoursEnd
        }
    }

    // MARK: - Meeting Detection

    func isInMeeting() -> Bool {
        guard pauseDuringMeetings, calendarAccessGranted else { return false }

        let now = Date()
        let calendars = eventStore.calendars(for: .event)

        // Look for events happening right now
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-60),  // 1 minute buffer
            end: now.addingTimeInterval(60),
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)

        // Filter for actual meetings (not all-day events, not declined)
        let activeMeetings = events.filter { event in
            !event.isAllDay &&
            event.status != .canceled &&
            (event.attendees?.count ?? 0) > 0  // Has attendees = likely a meeting
        }

        return !activeMeetings.isEmpty
    }

    // MARK: - Main Schedule Check

    func shouldPauseTimer() -> Bool {
        guard smartSchedulingEnabled else {
            isPausedBySchedule = false
            pauseReason = ""
            return false
        }

        // Check Focus Mode
        if pauseDuringFocusMode && isFocusModeActive() {
            isPausedBySchedule = true
            pauseReason = "Focus Mode active"
            return true
        }

        // Check Active Hours
        if !isWithinActiveHours() {
            isPausedBySchedule = true
            pauseReason = "Outside active hours"
            return true
        }

        // Check Meetings
        if isInMeeting() {
            isPausedBySchedule = true
            pauseReason = "In a meeting"
            return true
        }

        isPausedBySchedule = false
        pauseReason = ""
        return false
    }

    func updateScheduleStatus() {
        _ = shouldPauseTimer()
    }

    // MARK: - Helpers

    func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"  // e.g., "9 AM"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
