// The background script receives the active app from the native helper, maps it to a set of relevant tabs, and updates Chrome tab state accordingly.

const port = chrome.runtime.connectNative('com.example.contexthelper');

let currentActiveApp: string | null = null;

port.onMessage.addListener((message: { activeApp: string }) => {
    if (!message.activeApp) return;

    currentActiveApp = message.activeApp;

    // Trigger tab logic here
    handleActiveAppChange(message.activeApp);
});

port.onDisconnect.addListener(() => {
    console.error('Native helper disconnected');
});

function handleActiveAppChange(appName: string) {
    // Decide which tabs matter for this app
    // highlight them
}