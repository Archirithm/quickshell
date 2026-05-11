pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool inhibited: false

    function refresh() {
        statusPoller.running = true;
    }

    function toggle() {
        Quickshell.execDetached(["bash", "-c", root.inhibited ? "hypridle" : "killall hypridle"]);
        root.inhibited = !root.inhibited;
        debounceTimer.start();
    }

    Process {
        id: statusPoller
        command: ["bash", "-c", "pidof hypridle >/dev/null 2>&1 && echo active || echo inactive"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.inhibited = this.text.trim() !== "active"
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: debounceTimer
        interval: 350
        running: false
        repeat: false
        onTriggered: root.refresh()
    }
}
