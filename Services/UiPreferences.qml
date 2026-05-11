pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    readonly property string configDir: Paths.homeDir + "/.cache/quickshell"
    readonly property string filePath: configDir + "/ui-preferences.json"

    property bool dndEnabled: false
    property bool darkMode: false
    property bool storeReady: false

    function setDndEnabled(value) {
        root.dndEnabled = value;
        root.save();
    }

    function toggleDnd() {
        root.setDndEnabled(!root.dndEnabled);
    }

    function setDarkMode(value) {
        root.darkMode = value;
        root.save();
        Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", value ? "prefer-dark" : "default"]);
        themeDebounce.start();
    }

    function toggleDarkMode() {
        root.setDarkMode(!root.darkMode);
    }

    function save() {
        if (!root.storeReady)
            return;

        prefsFile.setText(JSON.stringify({
            "dndEnabled": root.dndEnabled
        }, null, 2));
    }

    Process {
        id: ensureStoreDir
        command: ["mkdir", "-p", root.configDir]
        running: true
        onExited: {
            root.storeReady = true;
            prefsFile.reload();
        }
    }

    FileView {
        id: prefsFile
        path: root.filePath

        onLoaded: {
            try {
                const parsed = JSON.parse(prefsFile.text().trim() || "{}");
                if (typeof parsed.dndEnabled === "boolean")
                    root.dndEnabled = parsed.dndEnabled;
            } catch (error) {
                console.log("UiPreferences failed to load:", error);
            }
        }

        onLoadFailed: {
            root.save();
        }
    }

    Process {
        id: themePoller
        command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.darkMode = this.text.toLowerCase().includes("prefer-dark")
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: themePoller.running = true
    }

    Timer {
        id: themeDebounce
        interval: 350
        running: false
        repeat: false
        onTriggered: themePoller.running = true
    }
}
