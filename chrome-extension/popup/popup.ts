/// <reference types="chrome"/>

// Establish a persistent connection to the native helper
// Chrome uses an IPC-like channel under the hood: messages are serialized to JSON and sent via stdin/stdout
const port = chrome.runtime.connectNative('com.example.contexthelper');

const activeAppDiv = document.getElementById('active-app') as HTMLDivElement;

// Listen for messages from the native helper
// Each message travels asynchronously over the port; Chrome automatically parses it from JSON to an object
port.onMessage.addListener((message: { activeApp: string }) => {
    if (message.activeApp) {
    activeAppDiv.textContent = message.activeApp;
  }
})

// Listen for when the connection to the helper closes
// This happens if the helper crashes or the extension is unloaded; Chrome fires an event so we can react safely
port.onDisconnect.addListener(() => {
  activeAppDiv.textContent = 'Helper disconnected';
});