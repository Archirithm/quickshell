import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config
import qs.Widget.common

WidgetPanel {
    id: root
    title: "网络配置"
    icon: "\uf1eb"
    closeAction: () => WidgetState.qsOpen = false

    property bool isActive: WidgetState.qsOpen && WidgetState.qsView === "network"
    property bool wifiEnabled: true
    property string currentTab: "wifi"

    onIsActiveChanged: {
        if (isActive) { scanWifi.running = true; networkMonitor.running = true } 
        else { networkMonitor.running = false }
    }

    headerTools: RowLayout {
        Theme { id: headerTheme }
        spacing: 12
        Text {
            text: "\uf021"
            font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 18
            color: headerTheme.subtext; opacity: scanWifi.running ? 0.5 : 1
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { wifiModel.clear(); scanWifi.running = true } }
            RotationAnimation on rotation { running: scanWifi.running; from: 0; to: 360; loops: Animation.Infinite; duration: 1000 }
        }
        
        Rectangle {
            width: 50; height: 26; radius: 13 
            color: root.wifiEnabled ? headerTheme.primary : headerTheme.outline
            
            Rectangle { 
                x: root.wifiEnabled ? 26 : 2; y: 2
                width: 22; height: 22; radius: 11; color: "white"
                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } } 
            }
            
            MouseArea { 
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.wifiEnabled = !root.wifiEnabled
                    if (!root.wifiEnabled) { wifiModel.clear(); scanWifi.running = false } 
                    else { scanWifi.running = true }
                    toggleWifiProc.running = true 
                }
            }
        }
    }

    Rectangle {
        Theme { id: tabTheme }
        Layout.fillWidth: true; height: 42
        color: tabTheme.surface; radius: 10
        RowLayout {
            anchors.fill: parent; anchors.margins: 4; spacing: 0
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; color: root.currentTab === "wifi" ? tabTheme.primary : "transparent"; radius: 6
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { 
                    anchors.centerIn: parent; text: "Wi-Fi"; font.bold: true; font.pixelSize: 14; 
                    // 【核心修复】：选中时使用深色的 on_primary，未选中时使用普通的 text
                    color: root.currentTab === "wifi" ? Colorscheme.on_primary : tabTheme.text 
                }
                MouseArea { anchors.fill: parent; onClicked: root.currentTab = "wifi" }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; color: root.currentTab === "ethernet" ? tabTheme.primary : "transparent"; radius: 6
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { 
                    anchors.centerIn: parent; text: "以太网"; font.bold: true; font.pixelSize: 14; 
                    // 【核心修复】：同上
                    color: root.currentTab === "ethernet" ? Colorscheme.on_primary : tabTheme.text 
                }
                MouseArea { anchors.fill: parent; onClicked: root.currentTab = "ethernet" }
            }
        }
    }

    StackLayout {
        Layout.fillWidth: true; Layout.fillHeight: true
        currentIndex: root.currentTab === "wifi" ? 0 : 1
        
        ColumnLayout {
            spacing: 8
            Theme { id: contentTheme }
            Text { text: "网络列表"; color: contentTheme.subtext; font.pixelSize: 14; font.bold: true; Layout.topMargin: 12 }

            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: 10; model: wifiModel // 加大间距
                
                delegate: Rectangle {
                    Theme { id: itemTheme }
                    height: 68; width: ListView.view.width; radius: 12; color: "transparent" // 加高项
                    border.width: 1; border.color: ma.containsMouse ? itemTheme.primary : "transparent"
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 14
                        Text {
                            text: "\uf1eb"; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 20 
                            color: model.connected ? itemTheme.primary : itemTheme.subtext
                            opacity: model.connected ? 1 : (model.signal / 100)
                        }
                        ColumnLayout {
                            spacing: 2; Layout.alignment: Qt.AlignVCenter
                            Text { text: model.ssid; font.bold: true; font.pixelSize: 14; color: model.connected ? itemTheme.primary : itemTheme.text }
                            RowLayout {
                                spacing: 6
                                Text { text: model.connected ? "\uf00c" : "\uf023"; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 11; color: model.connected ? itemTheme.primary : itemTheme.subtext }
                                Text { text: model.connected ? "已连接" : (model.security === "" ? "Open" : model.security); font.pixelSize: 12; color: model.connected ? itemTheme.primary : itemTheme.subtext }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            visible: ma.containsMouse || model.connected
                            width: model.connected ? 64 : 56; height: 32; radius: 8
                            color: model.connected ? Qt.rgba(itemTheme.error.r, itemTheme.error.g, itemTheme.error.b, 0.15) : Qt.rgba(itemTheme.primary.r, itemTheme.primary.g, itemTheme.primary.b, 0.15)

                            Text { 
                                anchors.centerIn: parent; text: model.connected ? "断开" : "连接"
                                color: model.connected ? itemTheme.error : itemTheme.primary
                                font.pixelSize: 12; font.bold: true 
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (model.connected) {
                                        disconnectProc.targetSsid = model.ssid; disconnectProc.running = true
                                        wifiModel.setProperty(index, "connected", false)
                                    } else {
                                        connectProc.targetSsid = model.ssid; connectProc.running = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Theme { id: ethTheme }
            ColumnLayout {
                anchors.centerIn: parent; spacing: 12
                Text { text: "\uf796"; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 48; color: ethTheme.outline; Layout.alignment: Qt.AlignHCenter }
                Text { text: "以太网设置暂不可用"; font.pixelSize: 14; color: ethTheme.subtext }
            }
        }
    }

    ListModel { id: wifiModel }

    Process { id: networkMonitor; command: ["nmcli", "monitor"]; running: root.isActive
        stdout: SplitParser { onRead: (data) => { const str = data.toLowerCase(); if (str.includes("connected") || str.includes("disconnected") || str.includes("unavailable") || str.includes("using connection")) { if (root.wifiEnabled) scanWifi.running = true } } }
    }
    Process { id: checkWifiStatus; command: ["nmcli", "radio", "wifi"]; running: root.isActive
        stdout: SplitParser { onRead: (data) => { let status = (data.trim() === "enabled"); root.wifiEnabled = status; if (status && wifiModel.count === 0) scanWifi.running = true } }
    }
    Process { id: scanWifi; command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list"]
        stdout: SplitParser { splitMarker: "\n"; onRead: (data) => parseWifiData(data) }
    }
    Process { id: toggleWifiProc; command: ["nmcli", "radio", "wifi", root.wifiEnabled ? "on" : "off"]; onExited: (code) => { if (root.wifiEnabled) scanWifi.running = true } }
    Process { id: connectProc; property string targetSsid: ""; command: ["nmcli", "device", "wifi", "connect", targetSsid] }
    Process { id: disconnectProc; property string targetSsid: ""; command: ["nmcli", "connection", "down", targetSsid] }

    function parseWifiData(line) {
        if (!root.wifiEnabled || line.trim() === "") return;
        let lastColon = line.lastIndexOf(":")
        let inUse = line.substring(lastColon + 1)
        let temp1 = line.substring(0, lastColon)
        let secondLastColon = temp1.lastIndexOf(":")
        let security = temp1.substring(secondLastColon + 1)
        let temp2 = temp1.substring(0, secondLastColon)
        let thirdLastColon = temp2.lastIndexOf(":")
        let signal = parseInt(temp2.substring(thirdLastColon + 1))
        let ssid = temp2.substring(0, thirdLastColon).replace(/\\:/g, ":")

        if (ssid === "") return;
        let isConnected = (inUse === "*");
        if (isConnected) { for(let i = 0; i < wifiModel.count; i++) { if (wifiModel.get(i).connected) wifiModel.setProperty(i, "connected", false); } }
        let existingIndex = -1;
        for(let i = 0; i < wifiModel.count; i++) { if (wifiModel.get(i).ssid === ssid) { existingIndex = i; break; } }
        if (existingIndex !== -1) {
            wifiModel.setProperty(existingIndex, "signal", signal); wifiModel.setProperty(existingIndex, "connected", isConnected);
            if (isConnected) wifiModel.move(existingIndex, 0, 1);
        } else {
            let item = { ssid: ssid, signal: signal, security: security === "" ? "Open" : security, connected: isConnected };
            if (isConnected) wifiModel.insert(0, item); else wifiModel.append(item);
        }
    }
}
