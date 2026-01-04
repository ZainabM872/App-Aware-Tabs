## Purpose
This Swift helper acts as a bridge between macOS system state and a Chrome extension. It detects which macOS application is currently frontmost and sends that information to the Chrome extension.  
It uses `NSWorkspace.shared.frontmostApplication` to get the active app and applies a debounce to prevent rapid-fire messages when apps change quickly.

## Architecture Overview
Chrome extensions are sandboxed and cannot access operating system–level information such as the currently focused application. This project uses this native helper to provide application context that Chrome extensions cannot access directly.

[ macOS Window Manager ]
        │
        │  - Which app is currently focused?
        ▼
[ Swift Native Helper ]
        │
        │  - Reads frontmost app via NSWorkspace
        │  - Debounces rapid focus changes
        │  - Serializes app name to JSON
        ▼
[ Native Messaging Stream ]
        │
        │  - Comunication method between helper and Chrome
        │  - 4-byte length prefix
        │  - UTF-8 JSON payload
        ▼
[ Chrome Extension (Service Worker) ]
        │
        │  - Receives JSON message from helper
        │  - Resolves tab behavior
        ▼
[ Chrome Tabs API ]
        │
        │  - Highlight / prioritize / reorder tabs

This architecture cleanly separates OS-specific logic from browser behavior, keeping the extension lightweight while leveraging native capabilities only where necessary.

## Native Messaging Protocol

Messages are sent to Chrome via `stdout` using Chrome’s Native Messaging protocol.

Each message consists of:
1. A 4-byte **little-endian unsigned integer** indicating message length
2. A UTF-8 encoded JSON payload

Example payload:
```json
{ "activeApp": "VS Code" }
```

## Challenges

1. <u>NSWorkspace Requires a RunLoop</u>

An early challenge was discovering that NSWorkspace does not update the frontmost application unless the process is running inside a RunLoop.

At first, a simple infinite loop was used to poll the active app:
```jsx
while true {
    print("app: " + (NSWorkspace.shared.frontmostApplication?
        .executableURL?
        .lastPathComponent ?? ""))
    sleep(1)
}
```

This does not work.

However, using a timer does:
```jsx
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    printApp()
}
```

Why this happens:
- NSWorkspace depends on AppKit event processing
- AppKit only processes events inside a RunLoop
- A while true loop with sleep() blocks the thread and never enters the RunLoop
- Using Timer works because timers are scheduled on the RunLoop, allowing AppKit to receive and process system events.

2. <u>Preventing Excessive Logging</u>

The helper polls the frontmost application every 0.1 seconds. Without safeguards, this caused the same application name to be logged repeatedly, even when no state change occurred. This was problematic for several reasons
- CPU overhead: Every print call performs string formatting, memory allocation, and I/O operations. At 0.1s intervals, this results in 10 log operations per second, all doing unnecessary work.
- Each message triggers parsing and tab operations. Without a guard, Chrome would process repeated messages for the same app. This could trigger hundreds of DOM updates and redraws per second, leading to sluggish UI, high CPU usage, and memory overhead.
- Repeatedly emitting identical messages hides meaningful state changes.

Solution – ```hasPrinted``` + Debouncing:

The ```hasPrinted``` flag ensures a message is only sent once per focus period.

Debouncing introduces a minimum threshold (e.g., 1 second) before sending a message, preventing transient focus changes from triggering unnecessary updates.

1. App is detected as frontmost → hasPrinted = false
2. If debounce threshold is passed and hasPrinted == false → send message, then set hasPrinted = true
3. While the same app is frontmost → no additional messages sent
4. If the user switches apps → reset hasPrinted = false for the new app

With ```hasPrinted``` and debouncing, the helper only sends meaningful messages when the active app actually changes and remains stable. This reduces CPU load, prevents flooding Chrome with redundant messages, minimizes DOM updates, and keeps logs clean.