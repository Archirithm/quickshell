pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool connected: activeConnectionType != ""
    property string activeConnection: "Disconnected"
    property string activeConnectionType: ""
    property int signalStrength: 100

    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property var wifiConnectTarget: null
    property var wifiNetworks: []
    property var savedWifiConnections: []
    readonly property bool passwordPromptActive: wifiNetworks.some(network => network.askingPassword)
    readonly property var activeWifi: wifiNetworks.find(n => n.active) || null
    readonly property var friendlyWifiNetworks: wifiNetworks.slice().sort((a, b) => {
        if (a.active && !b.active)
            return -1;
        if (!a.active && b.active)
            return 1;
        return b.strength - a.strength;
    })

    function refresh() {
        refreshProcess.running = true;
        signalProcess.running = true;
        wifiStatusProcess.running = true;
        savedConnectionsProcess.running = true;
        if (!passwordPromptActive)
            getNetworks.running = true;
    }

    function enableWifi(enabled = true) {
        root.wifiEnabled = enabled;
        if (!enabled)
            root.clearWifiNetworks();
        enableWifiProc.exec(["nmcli", "radio", "wifi", enabled ? "on" : "off"]);
    }

    function toggleWifi() {
        enableWifi(!wifiEnabled);
    }

    function rescanWifi() {
        if (!wifiEnabled || passwordPromptActive)
            return;
        wifiScanning = true;
        rescanProcess.running = true;
    }

    function connectToWifiNetwork(accessPoint) {
        if (!accessPoint)
            return;

        if (accessPoint.active) {
            disconnectWifiNetwork();
            return;
        }

        if (accessPoint.isSecure) {
            const savedConnection = savedConnectionForSsid(accessPoint.ssid);
            if (!savedConnection) {
                openPasswordPrompt(accessPoint);
                cleanupSecretRequestsForSsid(accessPoint.ssid);
                return;
            }

            accessPoint.askingPassword = false;
            root.wifiConnectTarget = accessPoint;
            connectProc.exec(["nmcli", "connection", "up", savedConnection.name]);
            return;
        }

        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;
        connectProc.exec(["nmcli", "dev", "wifi", "connect", accessPoint.ssid]);
    }

    function openPasswordPrompt(accessPoint) {
        if (!accessPoint)
            return;

        for (const network of root.wifiNetworks)
            network.askingPassword = network === accessPoint;
        accessPoint.askingPassword = true;
        root.wifiConnectTarget = null;
    }

    function cancelPasswordRequest(network) {
        if (!network)
            return;

        network.askingPassword = false;
        if (root.wifiConnectTarget === network)
            root.wifiConnectTarget = null;
        cleanupSecretRequestsForSsid(network.ssid);
        root.refresh();
    }

    function cleanupSecretRequestsForSsid(ssid) {
        if (!ssid || ssid.length === 0)
            return;

        cleanupSecretRequestsProcess.exec({
            "environment": {
                "SSID": ssid
            },
            "command": ["bash", "-c", 'nmcli -t -f NAME,TYPE connection show | while IFS=: read -r name type; do case "$type" in *wireless*|*wifi*) profile_ssid="$(nmcli -g 802-11-wireless.ssid connection show "$name" 2>/dev/null | head -n1)"; [ -n "$profile_ssid" ] || profile_ssid="$name"; [ "$profile_ssid" = "$SSID" ] || continue; flags="$(nmcli -g 802-11-wireless-security.psk-flags connection show "$name" 2>/dev/null | head -n1)"; case "$flags" in ""|*[!0-9]*) flags=0;; esac; if [ $((flags & 3)) -ne 0 ]; then nmcli connection down "$name" 2>/dev/null || true; nmcli connection modify "$name" connection.autoconnect no 2>/dev/null || true; nmcli connection delete "$name" 2>/dev/null || true; fi;; esac; done']
        });
    }

    function hasSavedSecret(ssid) {
        return savedConnectionForSsid(ssid) !== null;
    }

    function savedConnectionForSsid(ssid) {
        return root.savedWifiConnections.find(connection => connection.ssid === ssid) || null;
    }

    function disconnectWifiNetwork() {
        if (activeWifi)
            disconnectProc.exec(["nmcli", "connection", "down", activeWifi.ssid]);
    }

    function changePassword(network, password) {
        if (!network)
            return;

        if (network.isSecure && password.length === 0) {
            openPasswordPrompt(network);
            return;
        }

        network.askingPassword = false;
        root.wifiConnectTarget = network;
        changePasswordProc.exec({
            "environment": {
                "PASSWORD": password,
                "SSID": network.ssid
            },
            "command": ["bash", "-c", 'nmcli -t -f NAME,TYPE connection show | while IFS=: read -r name type; do case "$type" in *wireless*|*wifi*) profile_ssid="$(nmcli -g 802-11-wireless.ssid connection show "$name" 2>/dev/null | head -n1)"; [ -n "$profile_ssid" ] || profile_ssid="$name"; [ "$profile_ssid" = "$SSID" ] || continue; flags="$(nmcli -g 802-11-wireless-security.psk-flags connection show "$name" 2>/dev/null | head -n1)"; case "$flags" in ""|*[!0-9]*) flags=0;; esac; if [ $((flags & 3)) -ne 0 ]; then nmcli connection down "$name" 2>/dev/null || true; nmcli connection delete "$name" 2>/dev/null || true; fi;; esac; done; nmcli dev wifi connect "$SSID" password "$PASSWORD"']
        });
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]);
    }

    Process {
        id: refreshProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "con", "show", "--active"]
        
        stdout: StdioCollector {
            onStreamFinished: () => {
                if (this.text.trim() === "") {
                    root.activeConnectionType = ""
                    root.activeConnection = "Disconnected"
                    root.signalStrength = 0
                    return
                }
                
                const interfaces = this.text.split("\n");
                const activeInterface = interfaces[0];
                const fields = activeInterface.split(":");
                
                if (fields.length < 2) return;
                const connectionType = refreshProcess.getConnectionType(fields[1]);
                root.activeConnectionType = connectionType;
                root.activeConnection = connectionType != "" ? fields[0] : "Disconnected";
            }
        }

        function getConnectionType(nmcliOutput) {
            if (nmcliOutput.includes("ethernet")) return "ETHERNET";
            else if (nmcliOutput.includes("wireless")) return "WIFI";
            return "";
        }
    }

    Process {
        id: signalProcess
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL dev wifi | grep '^\\*' | cut -d':' -f2"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                const val = parseInt(this.text.trim());
                if (!isNaN(val)) {
                    root.signalStrength = val;
                }
            }
        }
    }

    Process {
        id: enableWifiProc
        onExited: {
            root.refresh();
            if (root.wifiEnabled)
                root.rescanWifi();
        }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiScanning = false;
                if (!root.passwordPromptActive)
                    getNetworks.running = true;
            }
        }
        onExited: {
            root.wifiScanning = false;
            if (!root.passwordPromptActive)
                getNetworks.running = true;
        }
    }

    Process {
        id: connectProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: {
                if (!root.passwordPromptActive)
                    getNetworks.running = true;
            }
        }
        stderr: SplitParser {
            onRead: line => {
                if (line.includes("Secrets were required") && root.wifiConnectTarget) {
                    const target = root.wifiConnectTarget;
                    root.cleanupSecretRequestsForSsid(target.ssid);
                    root.openPasswordPrompt(target);
                }
            }
        }
        onExited: exitCode => {
            if (root.wifiConnectTarget && exitCode !== 0) {
                const target = root.wifiConnectTarget;
                root.cleanupSecretRequestsForSsid(target.ssid);
                root.openPasswordPrompt(target);
            }
            root.wifiConnectTarget = null;
            root.refresh();
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: {
                if (!root.passwordPromptActive)
                    getNetworks.running = true;
            }
        }
        onExited: root.refresh()
    }

    Process {
        id: changePasswordProc
        onExited: exitCode => {
            if (root.wifiConnectTarget && exitCode !== 0)
                root.openPasswordPrompt(root.wifiConnectTarget);
            root.wifiConnectTarget = null;
            root.refresh();
        }
    }

    Process {
        id: cleanupSecretRequestsProcess
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        onExited: root.refresh()
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
                if (!root.wifiEnabled)
                    root.clearWifiNetworks();
            }
        }
    }

    Process {
        id: savedConnectionsProcess
        command: ["bash", "-c", 'nmcli -t -f NAME,TYPE connection show | while IFS=: read -r name type; do case "$type" in *wireless*|*wifi*) ssid="$(nmcli -g 802-11-wireless.ssid connection show "$name" 2>/dev/null | head -n1)"; [ -n "$ssid" ] || ssid="$name"; flags="$(nmcli -g 802-11-wireless-security.psk-flags connection show "$name" 2>/dev/null | head -n1)"; case "$flags" in ""|*[!0-9]*) flags=0;; esac; [ $((flags & 3)) -eq 0 ] && printf "%s\\t%s\\n" "$ssid" "$name";; esac; done']
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.passwordPromptActive)
                    return;

                const rawText = text.trim();
                if (rawText.length === 0) {
                    root.savedWifiConnections = [];
                    return;
                }

                root.savedWifiConnections = rawText.split("\n").map(line => {
                    const fields = line.split("\t");
                    return {
                        ssid: fields[0] || "",
                        name: fields[1] || fields[0] || ""
                    };
                }).filter(connection => connection.ssid.length > 0 && connection.name.length > 0);
            }
        }
    }

    Process {
        id: getNetworks
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                const rawText = text.trim();
                if (rawText.length === 0) {
                    root.clearWifiNetworks();
                    return;
                }

                const placeholder = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const escapedColon = new RegExp("\\\\:", "g");
                const placeholderColon = new RegExp(placeholder, "g");
                const allNetworks = rawText.split("\n").map(line => {
                    const fields = line.replace(escapedColon, placeholder).split(":");
                    return {
                        active: fields[0] === "yes",
                        strength: parseInt(fields[1]) || 0,
                        frequency: parseInt(fields[2]) || 0,
                        ssid: fields[3] || "",
                        bssid: fields.length > 4 && fields[4] ? fields[4].replace(placeholderColon, ":") : "",
                        security: fields[5] || ""
                    };
                }).filter(network => network.ssid.length > 0);

                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing || (network.active && !existing.active) || (!network.active && !existing.active && network.strength > existing.strength))
                        networkMap.set(network.ssid, network);
                }

                root.syncWifiNetworks(Array.from(networkMap.values()));
            }
        }
    }

    function clearWifiNetworks() {
        const networks = root.wifiNetworks.slice();
        while (networks.length > 0)
            networks.splice(0, 1)[0].destroy();
        root.wifiNetworks = [];
    }

    function syncWifiNetworks(nextNetworks) {
        const networks = root.wifiNetworks.slice();
        const destroyed = networks.filter(existing => !nextNetworks.find(next => next.frequency === existing.frequency && next.ssid === existing.ssid && next.bssid === existing.bssid));
        for (const network of destroyed)
            networks.splice(networks.indexOf(network), 1)[0].destroy();

        for (const nextNetwork of nextNetworks) {
            const match = networks.find(existing => nextNetwork.frequency === existing.frequency && nextNetwork.ssid === existing.ssid && nextNetwork.bssid === existing.bssid);
            if (match)
                match.lastIpcObject = nextNetwork;
            else
                networks.push(wifiAccessPointComponent.createObject(root, {
                    lastIpcObject: nextNetwork
                }));
        }

        root.wifiNetworks = networks;
    }

    Component {
        id: wifiAccessPointComponent

        QtObject {
            required property var lastIpcObject

            readonly property string ssid: lastIpcObject && lastIpcObject.ssid ? lastIpcObject.ssid : ""
            readonly property string bssid: lastIpcObject && lastIpcObject.bssid ? lastIpcObject.bssid : ""
            readonly property int strength: lastIpcObject && lastIpcObject.strength ? lastIpcObject.strength : 0
            readonly property int frequency: lastIpcObject && lastIpcObject.frequency ? lastIpcObject.frequency : 0
            readonly property bool active: lastIpcObject && lastIpcObject.active
            readonly property string security: lastIpcObject && lastIpcObject.security ? lastIpcObject.security : ""
            readonly property bool isSecure: security.length > 0

            property bool askingPassword: false
        }
    }

    Process {
        id: monitorProcess
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.refresh()
        }
    }

    Component.onCompleted: root.refresh()
}
