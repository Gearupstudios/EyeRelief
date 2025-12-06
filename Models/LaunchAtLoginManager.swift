import Foundation
import AppKit

class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published var launchAtLogin: Bool {
        didSet {
            if oldValue != launchAtLogin {
                setLaunchAtLogin(enabled: launchAtLogin)
            }
        }
    }

    private static let hasSetupDefaultKey = "hasSetupLaunchAtLoginDefault"

    init() {
        // Check if this is the first launch (default setup not done yet)
        let hasSetupDefault = UserDefaults.standard.bool(forKey: Self.hasSetupDefaultKey)

        if hasSetupDefault {
            // User has already been through setup, load their preference
            self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        } else {
            // First launch - default to enabled
            self.launchAtLogin = true
        }

        // Enable launch at login by default on first run
        ensureLaunchAtLoginEnabled()
    }

    private func ensureLaunchAtLoginEnabled() {
        let hasSetupDefault = UserDefaults.standard.bool(forKey: Self.hasSetupDefaultKey)

        if !hasSetupDefault {
            // First time setup - enable launch at login by default
            print("🚀 First launch - enabling launch at startup by default")
            enableLaunchAtLogin()
            UserDefaults.standard.set(true, forKey: Self.hasSetupDefaultKey)
            UserDefaults.standard.set(true, forKey: "launchAtLogin")
        } else {
            // Verify and sync state with system
            verifyLoginItemStatus()
        }
    }

    private func enableLaunchAtLogin() {
        let appPath = Bundle.main.bundlePath
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "EyeRelief"

        let script = """
        tell application "System Events"
            if not (exists login item "\(appName)") then
                make login item at end with properties {path:"\(appPath)", hidden:false, name:"\(appName)"}
            end if
        end tell
        """

        DispatchQueue.global(qos: .userInitiated).async {
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
                DispatchQueue.main.async {
                    if let error = error {
                        let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                        print("❌ Failed to enable launch at login by default: \(errorMessage)")
                        // Don't show alert on first launch to avoid annoying user
                        // Just silently fail and they can enable it manually
                    } else {
                        print("✅ Launch at login enabled by default")
                    }
                }
            }
        }
    }

    private func verifyLoginItemStatus() {
        // Check if app is actually in login items and sync state
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "EyeRelief"

        let checkScript = """
        tell application "System Events"
            return exists login item "\(appName)"
        end tell
        """

        DispatchQueue.global(qos: .userInitiated).async {
            if let appleScript = NSAppleScript(source: checkScript) {
                var error: NSDictionary?
                let result = appleScript.executeAndReturnError(&error)

                DispatchQueue.main.async {
                    if error == nil {
                        let actualStatus = result.booleanValue
                        if self.launchAtLogin != actualStatus {
                            print("🔄 Syncing login item state: cached=\(self.launchAtLogin), actual=\(actualStatus)")
                            UserDefaults.standard.set(actualStatus, forKey: "launchAtLogin")
                            self.launchAtLogin = actualStatus
                        }
                    }
                }
            }
        }
    }

    private func setLaunchAtLogin(enabled: Bool) {
        let appPath = Bundle.main.bundlePath
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "EyeRelief"

        print("📝 Setting launch at login: \(enabled) for \(appName) at \(appPath)")

        var script: String
        if enabled {
            script = """
            tell application "System Events"
                if not (exists login item "\(appName)") then
                    make login item at end with properties {path:"\(appPath)", hidden:false, name:"\(appName)"}
                end if
            end tell
            """
        } else {
            script = """
            tell application "System Events"
                if exists login item "\(appName)" then
                    delete login item "\(appName)"
                end if
            end tell
            """
        }

        DispatchQueue.global(qos: .userInitiated).async {
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
                DispatchQueue.main.async {
                    if let error = error {
                        let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                        let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? 0
                        print("❌ AppleScript error (\(errorNumber)): \(errorMessage)")

                        // Revert UI state on failure
                        self.launchAtLogin = !enabled

                        // Show appropriate error based on error type
                        if errorNumber == -1743 || errorMessage.contains("not allowed") {
                            self.showPermissionDeniedAlert()
                        } else {
                            self.showGenericErrorAlert(message: errorMessage)
                        }
                    } else {
                        print("✅ Login item \(enabled ? "added" : "removed") successfully")
                        UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
                    }
                }
            }
        }
    }

    private func showPermissionDeniedAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Permission Required"
            alert.informativeText = "EyeRelief needs permission to manage login items.\n\nPlease grant access in System Settings > Privacy & Security > Automation, then try again.\n\nAlternatively, you can manually add EyeRelief to your Login Items."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Privacy Settings")
            alert.addButton(withTitle: "Open Login Items")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open Privacy & Security > Automation
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(url)
                }
            } else if response == .alertSecondButtonReturn {
                self.openLoginItemsSettings()
            }
        }
    }

    private func showGenericErrorAlert(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Could Not Set Launch at Login"
            alert.informativeText = "An error occurred: \(message)\n\nYou can manually add EyeRelief to your Login Items instead."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Login Items")
            alert.addButton(withTitle: "OK")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                self.openLoginItemsSettings()
            }
        }
    }

    private func openLoginItemsSettings() {
        // Try modern macOS 13+ path first, fall back to older path
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback for older macOS - open Users & Groups
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Accounts.prefPane"))
        }
    }
}
