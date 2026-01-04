import Foundation
import AppKit

// Queries macOS for the currently focused (frontmost) application.
// This relies on AppKit updating focus state during the run loop.
func getFrontmostApplicationName() -> String {
    let activeApp = NSWorkspace.shared.frontmostApplication
    return activeApp?.localizedName ?? "Unknown App"
}

// Builds a JSON message containing the active app name
// Returns a Data object representing the JSON bytes, or nil if serialization fails
func buildJSONMessage(appName: String) -> Data? {
    let message = ["activeApp": appName] // Create a dictionary with one key-value pair: "activeApp": appName
    return try? JSONSerialization.data(withJSONObject: message) // Serialize the dictionary to JSON and return as Data
}

func sendMessage(currentApp: String) {
    // Build the JSON bytes from the app name
    // Short-circuiting: if serialization fails, exit early
    guard let jsonData = buildJSONMessage(appName: currentApp) else { return }
    
    // Convert the length of the JSON to a 4-byte little-endian integer
    var length = UInt32(jsonData.count).littleEndian

    // Use `withUnsafeBytes` to get a Data object containing the 4-byte length
    // This safely accesses the raw bytes of the integer
    let lengthData = withUnsafeBytes(of: &length) { Data($0) }

    // Write length header and JSON to stdout
    FileHandle.standardOutput.write(lengthData)
    FileHandle.standardOutput.write(jsonData)
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
            sendMessage(currentApp: currentApp)
            currentAppStartTime = Date() 
            hasPrinted = true 
        }
    }
}

RunLoop.current.run()