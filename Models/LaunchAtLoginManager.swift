import Foundation
import AppKit

class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published var launchAtLogin: Bool {
        didSet {
            if oldValue != launchAtLogin {
                setLaunchAtLogin(enabled: launchAtLogin)
                UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            }
        }
    }

    init() {
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
    }

    private func setLaunchAtLogin(enabled: Bool) {
        let appPath = Bundle.main.bundlePath
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "EyeRelief"

        var script: String
        if enabled {
            script = """
            tell application "System Events"
                if not (exists login item "\(appName)") then
                    make login item at end with properties {path:"\(appPath)", hidden:false}
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
                        print("❌ AppleScript error: \(error)")
                    } else {
                        print("✅ Login item \(enabled ? "added" : "removed")")
                    }
                }
            }
        }
    }
}
