import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common

Item {
    id: root

    required property var audioNode
    
    readonly property real volume: audioNode ? audioNode.volume : 0
    readonly property bool isMuted: audioNode ? audioNode.muted : false
    
    // ============================================================
    // 【核心修复 1】：新增用于 UI 显示的视觉音量。静音时强行归零！
    // ============================================================
    readonly property real displayVolume: root.isMuted ? 0.0 : root.volume

    readonly property bool isInteractionActive: hoverArea.containsMouse || dragArea.pressed

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton 
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 16

        // ==========================================
        // 左侧：Material Symbols 图标
        // ==========================================
        Text {
            id: volIcon
            // 【核心修复 2】：使用 Material Symbols 语义化名称，彻底告别 Unicode 乱码
            text: root.isMuted ? "volume_off" : "volume_up"
            font.family: "Material Symbols Outlined" 
            font.pixelSize: 24 
            color: "white"
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                anchors.margins: -10 
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.audioNode) root.audioNode.muted = !root.audioNode.muted
            }
        }

        // ==========================================
        // 中间：拖拽进度条 (静音时归零)
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 6 
            Layout.alignment: Qt.AlignVCenter
            
            Rectangle {
                anchors.fill: parent
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.2) 
            }

            Rectangle {
                id: fillRect
                height: parent.height
                radius: 3
                color: "white"
                // 使用 displayVolume 替代 volume，静音时进度条瞬间缩回
                width: Math.max(height, root.displayVolume * parent.width)
                
                Behavior on width { 
                    enabled: !dragArea.pressed
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuint } 
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                anchors.margins: -10 
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                function setVol(mouseX) {
                    if (!root.audioNode) return
                    let p = mouseX / width
                    if (p < 0) p = 0
                    if (p > 1) p = 1
                    root.audioNode.volume = p
                    
                    if (root.isMuted) root.audioNode.muted = false
                }

                onPressed: (mouse) => setVol(mouse.x)
                onPositionChanged: (mouse) => setVol(mouse.x)
            }
        }

        // ==========================================
        // 右侧：音量百分比数值 (静音时显示 0)
        // ==========================================
        Text {
            // 使用 displayVolume 替代 volume，静音时数字瞬间变 0
            text: Math.round(root.displayVolume * 100)
            color: "white" 
            font.pixelSize: 15
            font.bold: true
            font.family: "JetBrainsMono Nerd Font" 
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: 32 
            horizontalAlignment: Text.AlignRight
        }
    }
}
