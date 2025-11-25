import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 AppDelegate applicationDidFinishLaunching called!")

        // Set notification center delegate to handle foreground notifications
        UNUserNotificationCenter.current().delegate = self
        print("🔔 Notification center delegate set")

        // Request notification permissions immediately at launch
        requestNotificationPermissions()
    }

    private func requestNotificationPermissions() {
        print("📱 Requesting notification permissions at launch...")

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📋 Current notification status: \(settings.authorizationStatus.rawValue)")

            switch settings.authorizationStatus {
            case .notDetermined:
                // First time - request permission
                print("🔔 Permission not determined, requesting...")
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            print("✅ Notification permission granted at launch!")
                        } else {
                            print("❌ Notification permission denied at launch")
                            self.showPermissionAlert()
                        }
                        if let error = error {
                            print("❌ Error requesting permission: \(error.localizedDescription)")
                        }
                    }
                }
            case .denied:
                print("❌ Notifications are denied - showing alert")
                DispatchQueue.main.async {
                    self.showPermissionAlert()
                }
            case .authorized, .provisional, .ephemeral:
                print("✅ Notifications are already authorized")
            @unknown default:
                print("⚠️ Unknown notification status")
            }
        }
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Notifications Disabled"
        alert.informativeText = "EyeRelief needs notification permission to remind you to take eye breaks. Please enable notifications in System Settings > Notifications > EyeRelief."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings to Notifications
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Allow app to terminate properly
        return .terminateNow
    }

    // MARK: - UNUserNotificationCenterDelegate

    // This method is called when a notification is about to be presented while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Notification will present while app is in foreground")
        // Show notification with sound and banner even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // This method is called when the user interacts with a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 User interacted with notification: \(response.notification.request.identifier)")
        completionHandler()
    }
}