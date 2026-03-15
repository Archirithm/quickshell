import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.Widget.common
import qs.config
import qs.Widget.audio
import QtQuick.Controls

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
            Theme { id: itemTheme }

            required property PwLinkGroup modelData
            property var appNode: modelData.source

            width: ListView.view.width
            // 【修复Bug】将高度从 50 增加到 56，为顶部水滴预留空间
            height: 56 
            radius: 8
            color: "transparent"
            border.width: 1
            // 取消鼠标悬浮时的高亮，保持纯净
            border.color: "transparent" 

            PwObjectTracker { objects: [ appNode ] }

            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true }

            RowLayout {
                anchors.fill: parent
                // 【修复Bug】原先 margins 是统一的 10，现在增加顶部边距，将主体内容向下推
                anchors.topMargin: 16 
                anchors.bottomMargin: 10
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 12

                // 应用图标 (保持你原有的逻辑不变)
                Image {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    visible: source != ""
                    
                    source: {
                        const iconProperty = appNode.properties["application.icon-name"] || "";
                        const binaryName = appNode.properties["application.process.binary"] || "";
                        if (iconProperty.includes("chromium") || binaryName.includes("chromium")) {
                            return "image://icon/google-chrome";
                        }
                        let finalIcon = iconProperty || binaryName || "audio-card";
                        return `image://icon/${finalIcon}`;
                    }
                    onStatusChanged: {
                        if (status === Image.Error) {
                            source = "image://icon/audio-card";
                        }
                    }
                }

                // 应用名称 + 迷你音量条
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text { 
                            text: appNode.properties["application.name"] || appNode.name
                            font.bold: true
                            font.pixelSize: 12
                            color: itemTheme.text
                            elide: Text.ElideRight
                            Layout.fillWidth: true 
                        }
                        // 已经删除了右侧的百分比 Text 节点
                    }

                    // 全新水滴样式迷你音量条
                    Item {
                        Layout.fillWidth: true
                        height: 14 // 略微增加高度以容纳粗线条手柄

                        // 1. 背景与填充轨道
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Qt.rgba(itemTheme.text.r, itemTheme.text.g, itemTheme.text.b, 0.1)

                            Rectangle {
                                height: parent.height
                                width: parent.width * appNode.audio.volume
                                radius: 3
                                color: itemTheme.primary
                            }
                        }

                        // 2. 粗线条指示器与水滴提示
                        Rectangle {
                            id: handle
                            width: 4  // 粗线条宽度
                            height: 14
                            radius: 2
                            color: itemTheme.text 
                            // 确保手柄始终在轨道范围内
                            x: Math.max(0, Math.min(parent.width * appNode.audio.volume - width / 2, parent.width - width))
                            anchors.verticalCenter: parent.verticalCenter

                            // 水滴形提示框
                            Item {
                                width: 26
                                height: 26
                                anchors.bottom: parent.top
                                anchors.bottomMargin: 4
                                anchors.horizontalCenter: parent.horizontalCenter
                                // 仅在鼠标悬浮或按住拖拽时显示
                                visible: sliderMouseArea.containsMouse || sliderMouseArea.pressed
                                
                                // 利用旋转绘制水滴
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 13 
                                    color: itemTheme.primary
                                    rotation: 45 // 旋转45度

                                    // 覆盖右下角使其变成直角，旋转后正好成为朝下的尖角
                                    Rectangle {
                                        width: 13
                                        height: 13
                                        x: 13
                                        y: 13
                                        color: parent.color
                                    }
                                }

                                // 提示文字（正向显示）
                                Text {
                                    anchors.centerIn: parent
                                    text: Math.round(appNode.audio.volume * 100)
                                    color: itemTheme.surface 
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }

                        // 3. 交互控制
                        MouseArea {
                            id: sliderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            function updateVolume(mouse) {
                                let v = mouse.x / width
                                if (v < 0) v = 0
                                if (v > 1) v = 1
                                appNode.audio.volume = v
                            }

                            onPressed: (mouse) => updateVolume(mouse)
                            onPositionChanged: (mouse) => {
                                if (pressed) updateVolume(mouse)
                            }
                        }
                    }
                }
            }
        }
    }
}
