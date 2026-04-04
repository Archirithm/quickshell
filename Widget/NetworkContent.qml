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
    icon: "wifi" 
    closeAction: () => WidgetState.qsOpen = false

    property bool isActive: WidgetState.qsOpen && WidgetState.qsView === "network"
    property bool wifiEnabled: true
    property string currentTab: "wifi"
    
    property string mdFont: "Material Symbols Outlined"

    onIsActiveChanged: {
        if (isActive) { scanWifi.running = true; networkMonitor.running = true } 
        else { networkMonitor.running = false }
    }

    headerTools: RowLayout {
        Theme { id: headerTheme }
        spacing: 12
        
        Text {
            text: "sync"
            font.family: root.mdFont; font.pixelSize: 20
            color: headerTheme.subtext; opacity: scanWifi.running ? 0.5 : 1
            MouseArea { 
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                onClicked: { wifiModel.clear(); scanWifi.running = true } 
            }
            RotationAnimation on rotation { 
                running: scanWifi.running; from: 0; to: 360; loops: Animation.Infinite; duration: 1000 
            }
        }
        
        // 【优化】：缩小后的头部 Switch
        Rectangle {
            id: mainSwitch
            width: 44; height: 24; radius: 12 
            color: root.wifiEnabled ? headerTheme.primary : "transparent"
            border.width: root.wifiEnabled ? 0 : 2
            border.color: headerTheme.outline
            Behavior on color { ColorAnimation { duration: 250 } }
            
            Rectangle { 
                // 开启时16px，关闭时12px
                width: root.wifiEnabled ? 16 : 12
                height: root.wifiEnabled ? 16 : 12
                radius: width / 2
                x: root.wifiEnabled ? parent.width - width - 4 : 6
                anchors.verticalCenter: parent.verticalCenter
                color: root.wifiEnabled ? Colorscheme.on_primary : headerTheme.outline
                
                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } 
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 250 } }

                Text {
                    anchors.centerIn: parent
                    text: "check"
                    font.family: root.mdFont
                    font.pixelSize: 12 // 图标等比例缩小
                    font.bold: true
                    color: headerTheme.primary
                    opacity: root.wifiEnabled ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
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
        color: "transparent"
        
        RowLayout {
            anchors.fill: parent; spacing: 0
            
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                Text { 
                    anchors.centerIn: parent
                    text: "Wi-Fi"; font.bold: true; font.pixelSize: 14; 
                    color: root.currentTab === "wifi" ? tabTheme.primary : tabTheme.text 
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Rectangle {
                    width: 48; height: 3; radius: 1.5
                    color: tabTheme.primary
                    anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                    opacity: root.currentTab === "wifi" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
                MouseArea { anchors.fill: parent; onClicked: root.currentTab = "wifi" }
            }
            
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                Text { 
                    anchors.centerIn: parent
                    text: "以太网"; font.bold: true; font.pixelSize: 14; 
                    color: root.currentTab === "ethernet" ? tabTheme.primary : tabTheme.text 
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Rectangle {
                    width: 48; height: 3; radius: 1.5
                    color: tabTheme.primary
                    anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                    opacity: root.currentTab === "ethernet" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
                MouseArea { anchors.fill: parent; onClicked: root.currentTab = "ethernet" }
            }
        }
        
        Rectangle {
            width: parent.width; height: 1; color: tabTheme.outline
            anchors.bottom: parent.bottom; opacity: 0.3
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
                clip: true; spacing: 10; model: wifiModel 
                
                delegate: Rectangle {
                    Theme { id: itemTheme }
                    height: 68; width: ListView.view.width; radius: 12; color: "transparent" 
                    border.width: 1; border.color: ma.containsMouse ? itemTheme.primary : "transparent"
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 14
                        
                        Text {
                            text: "wifi"
                            font.family: root.mdFont; font.pixelSize: 24 
                            color: model.connected ? itemTheme.primary : itemTheme.subtext
                            opacity: model.connected ? 1 : (model.signal / 100)
                        }
                        
                        ColumnLayout {
                            spacing: 2; Layout.alignment: Qt.AlignVCenter
                            Text { text: model.ssid; font.bold: true; font.pixelSize: 14; color: model.connected ? itemTheme.primary : itemTheme.text }
                            RowLayout {
                                spacing: 4
                                Text { 
                                    text: model.connected ? "check" : "lock"
                                    font.family: root.mdFont; font.pixelSize: 14;
                                    color: model.connected ? itemTheme.primary : itemTheme.subtext 
                                }
                                Text { 
                                    text: model.connected ? "已连接" : (model.security === "" ? "Open" : model.security); 
                                    font.pixelSize: 12; color: model.connected ? itemTheme.primary : itemTheme.subtext 
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // 【优化】：缩小后的列表项 Switch
                        Rectangle {
                            visible: ma.containsMouse || model.connected
                            width: 44; height: 24; radius: 12 
                            color: model.connected ? itemTheme.primary : "transparent"
                            border.width: model.connected ? 0 : 2
                            border.color: itemTheme.outline
                            Behavior on color { ColorAnimation { duration: 250 } }
                            
                            Rectangle { 
                                width: model.connected ? 16 : 12
                                height: model.connected ? 16 : 12
                                radius: width / 2
                                x: model.connected ? parent.width - width - 4 : 6
                                anchors.verticalCenter: parent.verticalCenter
                                color: model.connected ? Colorscheme.on_primary : itemTheme.outline
                                
                                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } 
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 250 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "check"
                                    font.family: root.mdFont
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: itemTheme.primary
                                    opacity: model.connected ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (model.connected) {
                                        // 1. 断开：先立刻更新UI状态
                                        wifiModel.setProperty(index, "connected", false)
                                        // 2. 执行命令
                                        disconnectProc.targetSsid = model.ssid;
                                        disconnectProc.running = true
                                    } else {
                                        // 【核心修复】：乐观更新！立刻清除其他所有网络的连接状态，点亮当前网络
                                        for(let i = 0; i < wifiModel.count; i++) {
                                            if (wifiModel.get(i).connected) {
                                                wifiModel.setProperty(i, "connected", false)
                                            }
                                        }
                                        wifiModel.setProperty(index, "connected", true)
                                        
                                        // 执行连接命令
                                        connectProc.targetSsid = model.ssid;
                                        connectProc.running = true
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
                Text { text: "settings_ethernet"; font.family: root.mdFont; font.pixelSize: 56; color: ethTheme.outline; Layout.alignment: Qt.AlignHCenter }
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
    
    // 【核心修复】：添加 onExited 回调，无论 nmcli 执行成功还是失败，完成后都重新扫描一遍确保状态准确
    Process { 
        id: connectProc; property string targetSsid: ""; command: ["nmcli", "device", "wifi", "connect", targetSsid]; 
        onExited: scanWifi.running = true 
    }
    Process { 
        id: disconnectProc; property string targetSsid: ""; command: ["nmcli", "connection", "down", targetSsid]; 
        onExited: scanWifi.running = true 
    }

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
            wifiModel.setProperty(existingIndex, "signal", signal);
            wifiModel.setProperty(existingIndex, "connected", isConnected);
            if (isConnected) wifiModel.move(existingIndex, 0, 1);
        } else {
            let item = { ssid: ssid, signal: signal, security: security === "" ? "Open" : security, connected: isConnected };
            if (isConnected) wifiModel.insert(0, item); else wifiModel.append(item);
        }
    }
}
