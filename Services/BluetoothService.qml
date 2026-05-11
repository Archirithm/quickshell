pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool enabled: false
    property bool connected: false
    property string connectedName: ""

    function refresh() {
        statusPoller.running = true;
    }

    function toggle() {
        if (!root.available)
            return;

        Quickshell.execDetached(["bluetoothctl", "power", root.enabled ? "off" : "on"]);
        root.enabled = !root.enabled;
        if (!root.enabled) {
            root.connected = false;
            root.connectedName = "";
        }
        debounceTimer.start();
    }

    Process {
        id: statusPoller
        command: ["bash", "-c", `
            if ! command -v bluetoothctl >/dev/null 2>&1 || ! bluetoothctl show >/dev/null 2>&1; then
                echo "AVAILABLE:0"
                exit 0
            fi

            echo "AVAILABLE:1"
            if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
                echo "ENABLED:1"
                first_device="$(bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-)"
                if [ -n "$first_device" ]; then
                    echo "CONNECTED:1"
                    echo "NAME:$first_device"
                else
                    echo "CONNECTED:0"
                    echo "NAME:"
                fi
            else
                echo "ENABLED:0"
                echo "CONNECTED:0"
                echo "NAME:"
            fi
        `]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                const data = line.trim();
                if (data.length === 0)
                    return;

                if (data.startsWith("AVAILABLE:"))
                    root.available = data.substring(10) === "1";
                else if (data.startsWith("ENABLED:"))
                    root.enabled = data.substring(8) === "1";
                else if (data.startsWith("CONNECTED:"))
                    root.connected = data.substring(10) === "1";
                else if (data.startsWith("NAME:"))
                    root.connectedName = data.substring(5);
            }
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
