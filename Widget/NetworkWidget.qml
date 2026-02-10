import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config
import qs.Widget.common

SlideWindow {
    id: root
    title: "网络配置"
    icon: "\uf1eb"
    windowHeight: 420
    
    onIsOpenChanged: {
        WidgetState.networkOpen = isOpen
        // 窗口打开时强制刷新一次，并启动监控
        if (isOpen) {
            scanWifi.running = true
            networkMonitor.running = true
        } else {
            networkMonitor.running = false
        }
    }

    // --- 顶部工具栏 ---
    headerTools: RowLayout {
        Theme { id: headerTheme }
        
        // 刷新按钮
        Text {
            text: "\uf021"
            font.family: "Font Awesome 6 Free Solid"
            font.pixelSize: 16
            color: headerTheme.subtext
            opacity: scanWifi.running ? 0.5 : 1
            MouseArea { 
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { 
                    wifiModel.clear();
                    scanWifi.running = true 
                } 
            }
            RotationAnimation on rotation { 
                running: scanWifi.running;
                from: 0; to: 360; loops: Animation.Infinite; duration: 1000 
            }
        }
        
        Item { width: 10 }
        
        // Wi-Fi 开关
        Rectangle {
            width: 40; height: 22; radius: 11
            // 直接绑定 root.wifiEnabled，配合 onClicked 实现瞬间变色
            color: root.wifiEnabled ? headerTheme.primary : headerTheme.outline
            
            Rectangle { 
                x: root.wifiEnabled ? 20 : 2; y: 2
                width: 18; height: 18; radius: 9; color: "white"
                Behavior on x { NumberAnimation { duration: 200 } } 
            }
            
            MouseArea { 
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // 1. 【乐观更新】立即切换状态，不等待后台
                    root.wifiEnabled = !root.wifiEnabled
                    
                    // 2. 根据新状态立即处理 UI
                    if (!root.wifiEnabled) {
                        wifiModel.clear()      // 关：立刻清空列表
                        scanWifi.running = false
                    } else {
                        scanWifi.running = true // 开：立刻显示加载动画
                    }

                    // 3. 最后在后台执行命令
                    toggleWifiProc.running = true 
                }
            }
        }
    }

    // 默认值设为 true，但启动时 checkWifiStatus 会修正它
    property bool wifiEnabled: true
    property string currentTab: "wifi"

    // --- 界面内容 ---
    Rectangle {
        Theme { id: tabTheme }
        Layout.fillWidth: true
        height: 36
        color: tabTheme.surface
        radius: 8
        RowLayout {
            anchors.fill: parent; anchors.margins: 4; spacing: 0
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: root.currentTab === "wifi" ? tabTheme.primary : "transparent"
                radius: 6
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { 
                    anchors.centerIn: parent; text: "Wi-Fi"; font.bold: true
                    color: root.currentTab === "wifi" ? tabTheme.text : tabTheme.subtext 
                }
                MouseArea { anchors.fill: parent; onClicked: root.currentTab = "wifi" }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: root.currentTab === "ethernet" ? tabTheme.primary : "transparent"
                radius: 6
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { 
                    anchors.centerIn: parent; text: "以太网"; font.bold: true
                    color: root.currentTab === "ethernet" ? tabTheme.text : tabTheme.subtext 
                }
                MouseArea { anchors.fill: parent; onClicked: root.currentTab = "ethernet" }
            }
        }
    }

    StackLayout {
        Layout.fillWidth: true; Layout.fillHeight: true
        currentIndex: root.currentTab === "wifi" ? 0 : 1
        
        // === 页面 1: Wi-Fi 列表 ===
        ColumnLayout {
            spacing: 6
            Theme { id: contentTheme }
            Text { 
                text: "网络列表"; color: contentTheme.subtext; font.pixelSize: 12
                font.bold: true; Layout.topMargin: 4 
            }

            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: 6
                model: wifiModel
                
                delegate: Rectangle {
                    Theme { id: itemTheme }
                    height: 54; width: ListView.view.width
                    radius: 8; color: "transparent"
                    border.width: 1
                    border.color: ma.containsMouse ? itemTheme.primary : "transparent"
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 12
                        Text {
                            text: "\uf1eb"; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 16
                            color: model.connected ? itemTheme.primary : itemTheme.subtext
                            opacity: model.connected ? 1 : (model.signal / 100)
                        }
                        ColumnLayout {
                            spacing: 2; Layout.alignment: Qt.AlignVCenter
                            Text { 
                                text: model.ssid; font.bold: true
                                color: model.connected ? itemTheme.primary : itemTheme.text 
                            }
                            RowLayout {
                                spacing: 4
                                Text { 
                                    text: model.connected ? "\uf00c" : "\uf023"
                                    font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 10
                                    color: model.connected ? itemTheme.primary : itemTheme.subtext 
                                }
                                Text { 
                                    text: model.connected ? "已连接" : (model.security === "" ? "Open" : model.security)
                                    font.pixelSize: 11; color: model.connected ? itemTheme.primary : itemTheme.subtext 
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        // 连接/断开 按钮
                        Rectangle {
                            visible: ma.containsMouse || model.connected
                            width: model.connected ? 50 : 46; height: 26; radius: 4
                            color: model.connected ? Qt.rgba(itemTheme.error.r, itemTheme.error.g, itemTheme.error.b, 0.15) : Qt.rgba(itemTheme.primary.r, itemTheme.primary.g, itemTheme.primary.b, 0.15)

                            Text { 
                                anchors.centerIn: parent
                                text: model.connected ? "断开" : "连接"
                                color: model.connected ? itemTheme.error : itemTheme.primary
                                font.pixelSize: 11; font.bold: true 
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (model.connected) {
                                        disconnectProc.targetSsid = model.ssid
                                        disconnectProc.running = true
                                        // 视觉反馈：手动置为未连接，等待 Monitor 最终确认
                                        wifiModel.setProperty(index, "connected", false)
                                    } else {
                                        connectProc.targetSsid = model.ssid
                                        connectProc.running = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // === 页面 2: 以太网 ===
        Item {
            Theme { id: ethTheme }
            ColumnLayout {
                anchors.centerIn: parent; spacing: 10
                Text { 
                    text: "\uf796"; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 40
                    color: ethTheme.outline; Layout.alignment: Qt.AlignHCenter
                }
                Text { text: "以太网设置暂不可用"; color: ethTheme.subtext }
            }
        }
    }

    // --- 后台逻辑 ---

    ListModel { id: wifiModel }

    // 【核心组件】网络状态监听器
    Process {
        id: networkMonitor
        command: ["nmcli", "monitor"]
        // 只在窗口打开时运行
        running: root.isOpen
        stdout: SplitParser {
            onRead: (data) => {
                const str = data.toLowerCase();
                // 监听连接、断开、以及不可用状态
                if (str.includes("connected") || 
                    str.includes("disconnected") || 
                    str.includes("unavailable") ||
                    str.includes("using connection")) {
                    
                    // 如果网络是开启状态，才去扫描
                    if (root.wifiEnabled) {
                        scanWifi.running = true
                    }
                }
            }
        }
    }

    // 初始化状态检查
    Process {
        id: checkWifiStatus
        command: ["nmcli", "radio", "wifi"]
        running: root.isOpen
        stdout: SplitParser {
            onRead: (data) => {
                // 这里只在组件打开的瞬间同步一次真实状态
                // 之后的切换完全由 Toggle 按钮的乐观逻辑控制
                let status = (data.trim() === "enabled")
                root.wifiEnabled = status
                if (status && wifiModel.count === 0) scanWifi.running = true
            }
        }
    }

    Process {
        id: scanWifi
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => parseWifiData(data)
        }
    }

    Process { 
        id: toggleWifiProc
        // 直接使用 root.wifiEnabled，因为点击时我们已经改过这个值了
        // 如果现在是 true，意味着用户想开，我们就发 'on'
        command: ["nmcli", "radio", "wifi", root.wifiEnabled ? "on" : "off"]
        
        onExited: (code) => { 
            // 乐观更新后，这里主要是兜底
            // 如果开启了，确保扫描一次
            if (root.wifiEnabled) {
                scanWifi.running = true
            }
        } 
    }
    
    Process { 
        id: connectProc
        property string targetSsid: ""
        command: ["nmcli", "device", "wifi", "connect", targetSsid]
    }
    
    Process { 
        id: disconnectProc
        property string targetSsid: ""
        command: ["nmcli", "connection", "down", targetSsid]
    }

    function parseWifiData(line) {
        // 【关键保护】如果网络已关闭，不再处理任何扫描数据
        // 这防止了后台残留的扫描结果突然蹦出来
        if (!root.wifiEnabled) return;

        if (line.trim() === "") return;
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
        if (isConnected) {
            for(let i = 0; i < wifiModel.count; i++) {
                if (wifiModel.get(i).connected) {
                    wifiModel.setProperty(i, "connected", false);
                }
            }
        }

        let existingIndex = -1;
        for(let i = 0; i < wifiModel.count; i++) {
            if (wifiModel.get(i).ssid === ssid) {
                existingIndex = i;
                break;
            }
        }

        if (existingIndex !== -1) {
            wifiModel.setProperty(existingIndex, "signal", signal);
            wifiModel.setProperty(existingIndex, "connected", isConnected);
            if (isConnected) {
                wifiModel.move(existingIndex, 0, 1); 
            }
        } else {
            let item = { 
                ssid: ssid, 
                signal: signal, 
                security: security === "" ? "Open" : security, 
                connected: isConnected 
            };
            
            if (isConnected) {
                wifiModel.insert(0, item);
            } else {
                wifiModel.append(item);
            }
        }
    }
}
