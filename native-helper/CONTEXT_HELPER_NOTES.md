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

