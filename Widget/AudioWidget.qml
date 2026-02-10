import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.Widget.common
import qs.config
import qs.Widget.audio

SlideWindow {
    id: root
    title: "混音器"
    icon: "\uf1de"
    
    windowHeight: 360
    
    extraTopMargin: WidgetState.networkOpen ? (420 + 10) : 0
    
    onIsOpenChanged: WidgetState.audioOpen = isOpen

    headerTools: Text {
        // 【修复1】这里需要 Theme 实例，因为 headerTools 是动态加载的
        Theme { id: theme }
        
        text: "\uf013"
        font.family: "Font Awesome 6 Free Solid"
        font.pixelSize: 18
        color: theme.subtext
        MouseArea { 
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["pavucontrol"]) 
        }
    }

    // --- Pipewire 逻辑 ---
    property var defaultSink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [ root.defaultSink ] }
    PwNodeLinkTracker { id: appTracker; node: root.defaultSink }
    
    function isHeadphone(node) {
        if (!node) return false;
        const icon = node.properties["device.icon-name"] || ""; 
        const desc = node.description || "";
        return icon.includes("headphone") || desc.toLowerCase().includes("headphone") || desc.toLowerCase().includes("耳机");
    }

    // --- 界面内容 ---
    
    // 1. 主音量卡片
    Rectangle {
        Layout.fillWidth: true
        height: 90
        color: theme.surface
        radius: theme.radius
        border.width: 1
        border.color: Qt.rgba(0,0,0,0.05)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text { 
                    text: isHeadphone(root.defaultSink) ? "\uf025" : "\uf028"
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 16
                    color: theme.primary 
                }
                Text { 
                    text: root.defaultSink ? (root.defaultSink.description || root.defaultSink.name) : "未找到设备"
                    font.bold: true
                    color: theme.text
                    elide: Text.ElideRight
                    Layout.fillWidth: true 
                }
                Text { 
                    text: root.defaultSink ? Math.round(root.defaultSink.audio.volume * 100) + "%" : "0%"
                    font.bold: true
                    color: theme.primary 
                }
            }

            // 复用 VolumeSlider
            VolumeSlider { 
                node: root.defaultSink
                isHeadphone: root.isHeadphone(root.defaultSink)
            }
        }
    }

    // 2. 应用程序列表
    Text { 
        text: "应用程序"
        font.pixelSize: 12
        color: theme.subtext
        font.bold: true
        Layout.topMargin: 4 
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 8
        
        model: appTracker.linkGroups

        delegate: Rectangle {
            // 【修复2】这里必须实例化 Theme，否则下面的颜色找不到 theme 对象
            Theme { id: itemTheme }

            required property PwLinkGroup modelData
            property var appNode: modelData.source

            width: ListView.view.width
            height: 50
            radius: 8
            color: "transparent"
            border.width: 1
            // 使用 itemTheme
            border.color: ma.containsMouse ? itemTheme.primary : "transparent"
            Behavior on border.color { ColorAnimation { duration: 150 } }

            PwObjectTracker { objects: [ appNode ] }

            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                // 应用图标
                Image {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    visible: source != ""
                    
                    // 【修改逻辑】将所有 Chromium 相关的图标强制映射为 google-chrome
                    source: {
                        const iconProperty = appNode.properties["application.icon-name"] || "";
                        const binaryName = appNode.properties["application.process.binary"] || "";
                        
                        // 检查属性或二进制名称中是否包含 chromium
                        if (iconProperty.includes("chromium") || binaryName.includes("chromium")) {
                            return "image://icon/google-chrome";
                        }
                        
                        // 其他应用保持原有逻辑
                        let finalIcon = iconProperty || binaryName || "audio-card";
                        return `image://icon/${finalIcon}`;
                    }

                    // 容错处理：如果图标加载失败，回退到通用音频图标
                    onStatusChanged: {
                        if (status === Image.Error) {
                            source = "image://icon/audio-card";
                        }
                    }
                }

                // 应用名称 + 音量条
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text { 
                            text: appNode.properties["application.name"] || appNode.name
                            font.bold: true
                            font.pixelSize: 12
                            // 使用 itemTheme
                            color: itemTheme.text
                            elide: Text.ElideRight
                            Layout.fillWidth: true 
                        }
                        Text { 
                            text: Math.round(appNode.audio.volume * 100) + "%"
                            font.pixelSize: 10
                            // 使用 itemTheme
                            color: itemTheme.subtext 
                        }
                    }

                    // 迷你音量条
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        // 使用 itemTheme
                        color: Qt.rgba(itemTheme.text.r, itemTheme.text.g, itemTheme.text.b, 0.1)

                        Rectangle {
                            height: parent.height
                            width: parent.width * appNode.audio.volume
                            radius: 3
                            // 【关键修复】这里之前是白色，现在使用了 itemTheme.primary
                            color: itemTheme.primary
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => {
                                let v = mouse.x / width
                                if (v < 0) v = 0; if (v > 1) v = 1;
                                appNode.audio.volume = v
                            }
                            onPositionChanged: (mouse) => {
                                let v = mouse.x / width
                                if (v < 0) v = 0; if (v > 1) v = 1;
                                appNode.audio.volume = v
                            }
                        }
                    }
                }
            }
        }
    }
}
