pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
        id: root

        property bool wifiEnabled: false
        property bool bluetoothEnabled: false
        property bool bluetoothConnected: false 
        property bool caffeineEnabled: false 
        property bool dndEnabled: false      
        property real brightnessValue: 0.5

        Process {
                id: statusPoller
                command: ["bash", "-c", `
                        WIFI=$(nmcli -t -f WIFI g 2>/dev/null)
                        echo "WIFI:$WIFI"
                        
                        BT_PWR=$(bluetoothctl show 2>/dev/null | grep -c 'Powered: yes' || echo 0)
                        if [ "$BT_PWR" -gt 0 ]; then
                                BT_CONN=$(bluetoothctl devices Connected 2>/dev/null | wc -l)
                                [ "$BT_CONN" -gt 0 ] && echo "BT:connected" || echo "BT:on"
                        else
                                echo "BT:off"
                        fi
                        
                        if pidof hypridle >/dev/null; then IDLE="active"; else IDLE="inactive"; fi
                        echo "IDLE:$IDLE"
                        
                        BRI=$(brightnessctl -m 2>/dev/null | awk -F, '{print substr($4, 1, length($4)-1)}')
                        echo "BRI:$BRI"
                `]
                running: true 

                stdout: SplitParser {
                        splitMarker: "\n"
                        onRead: (line) => {
                                let data = line.trim();
                                if (data === "") return;

                                if (data.startsWith("WIFI:")) root.wifiEnabled = (data.substring(5) === "enabled");
                                else if (data.startsWith("BT:")) {
                                        let state = data.substring(3);
                                        root.bluetoothEnabled = (state !== "off");
                                        root.bluetoothConnected = (state === "connected");
                                }
                                else if (data.startsWith("IDLE:")) root.caffeineEnabled = (data.substring(5) !== "active");
                                else if (data.startsWith("BRI:")) {
                                        let b = parseInt(data.substring(4));
                                        if (!isNaN(b)) root.brightnessValue = b / 100.0;
                                }
                        }
                }
        }

        Timer {
                id: pollTimer
                interval: 5000; running: true; repeat: true
                onTriggered: statusPoller.running = true
        }

        Timer {
                id: debounceTimer
                interval: 200; running: false; repeat: false
                onTriggered: statusPoller.running = true
        }

        function toggleWifi() {
                Quickshell.execDetached(["bash", "-c", root.wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"]);
                root.wifiEnabled = !root.wifiEnabled; 
                debounceTimer.start();
        }

        function toggleBluetooth() {
                Quickshell.execDetached(["bash", "-c", root.bluetoothEnabled ? "bluetoothctl power off" : "bluetoothctl power on"]);
                root.bluetoothEnabled = !root.bluetoothEnabled; 
                root.bluetoothConnected = false; 
                debounceTimer.start();
        }

        function toggleCaffeine() {
                Quickshell.execDetached(["bash", "-c", root.caffeineEnabled ? "hypridle" : "killall hypridle"]);
                root.caffeineEnabled = !root.caffeineEnabled;
                debounceTimer.start();
        }

        function toggleDnd() {
                root.dndEnabled = !root.dndEnabled;
        }

        function setBrightness(val) {
                let pct = Math.round(Math.max(0.01, Math.min(1.0, val)) * 100);
                Quickshell.execDetached(["brightnessctl", "set", pct + "%"]);
                root.brightnessValue = val;
        }
}
