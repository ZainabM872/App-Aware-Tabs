import Foundation
import AppKit

// Queries macOS for the currently focused (frontmost) application.
// This relies on AppKit updating focus state during the run loop.
func getFrontmostApplicationName() -> String {
    let activeApp = NSWorkspace.shared.frontmostApplication
    return activeApp?.localizedName ?? "Unknown App"
}

// Separated into its own function so the timer callback stays lightweight.
// FUTURE: Replace the print line with native messaging
func printApp() {
    print("app: " + (getFrontmostApplicationName()))
}

var lastActiveApp: String? = nil
let debounceThreshold: TimeInterval = 1
var currentAppStartTime = Date()
var hasPrinted = false

Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
    let currentApp = getFrontmostApplicationName()

    // Check if the app has changed since last poll
    if (currentApp != lastActiveApp) {
        // A new app has been opened. Its stored in lastActiveApp, the timer is reset for debounce, and hasPrinted is set to false
        lastActiveApp = currentApp
        currentAppStartTime = Date()
        hasPrinted = false
    } else {
        // The same app is still active. Check if it has been active long enough
        // Only print if debounce threshold has passed and we haven’t printed yet
        if (Date().timeIntervalSince(currentAppStartTime) > debounceThreshold && !hasPrinted) {
            print("Frontmost app (debounced): \(currentApp)") // FUTURE: send this to Chrome via native messaging
            currentAppStartTime = Date() 
            hasPrinted = true 
        }
    }
}

RunLoop.current.run()
