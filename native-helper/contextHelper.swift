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
    print("app: " + (getFrontmostApplicationName() ?? ""))
}

Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { 
    _ in printApp()
}

RunLoop.current.run()
