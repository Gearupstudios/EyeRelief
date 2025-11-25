import Foundation
import UserNotifications
#if canImport(AppKit)
import AppKit
#endif

class NotificationManager: ObservableObject {
    @Published var isAuthorized: Bool = false
    private var hasRequestedPermission = false

    init() {
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
                print("📋 Notification authorization: \(self.isAuthorized)")
            }
        }
    }

    func requestPermission() {
        guard !hasRequestedPermission else {
            print("🔔 Permission already requested, checking current status...")
            checkAuthorizationStatus()
            return
        }

        hasRequestedPermission = true
        print("🔔 Requesting notification permissions...")

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    print("✅ Notification permission granted")
                } else {
                    print("❌ Notification permission denied")
                }
                if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }

    func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📋 Notification Settings:")
            print("   Authorization Status: \(settings.authorizationStatus.rawValue)")
            print("   Alert Setting: \(settings.alertSetting.rawValue)")
            print("   Sound Setting: \(settings.soundSetting.rawValue)")
            print("   Badge Setting: \(settings.badgeSetting.rawValue)")
        }
    }

    func showNotification() {
        print("🔔 Attempting to show notification...")

        // Check authorization first and proceed with notification
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            print("📋 Current authorization status: \(settings.authorizationStatus.rawValue)")

            guard settings.authorizationStatus == .authorized else {
                print("⚠️ Notifications not authorized! Cannot show notification.")
                DispatchQueue.main.async {
                    self?.isAuthorized = false
                    self?.showNotificationDisabledAlert()
                }
                return
            }

            // Create and send the notification
            let content = UNMutableNotificationContent()
            content.title = "Eye Break Reminder"
            content.body = "Time to rest your eyes! Look at something 20 feet away for 20 seconds."
            content.sound = UNNotificationSound.default

            // Use a fixed identifier to replace previous notifications
            let request = UNNotificationRequest(
                identifier: "eyerelief-break-reminder",
                content: content,
                trigger: nil // Immediate delivery
            )

            // Remove any pending notifications first
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["eyerelief-break-reminder"])

            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error showing notification: \(error.localizedDescription)")
                    } else {
                        print("✅ Notification delivered successfully!")
                    }
                }
            }
        }
    }

    private func showNotificationDisabledAlert() {
        #if canImport(AppKit)
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Notifications Disabled"
            alert.informativeText = "Please enable notifications for EyeRelief in System Settings to receive eye break reminders."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "OK")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        #endif
    }
}