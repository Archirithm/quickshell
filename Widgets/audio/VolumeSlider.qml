import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Common
import qs.Widgets.common

Item {
    id: root
    property var node
    property bool isHeadphone: false

    Layout.fillWidth: true
    // 给气泡留出足够的展示空间
    implicitHeight: 32 

    property bool isMuted: node ? node.audio.muted : false

    Slider {
        id: control
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.node !== null

        // 绑定节点音量，如果静音则显示为 0
        Binding {
            target: control
            property: "value"
            value: isMuted ? 0 : (root.node ? root.node.audio.volume : 0)
            when: !control.pressed
        }

        // 拖动时同步音量并自动解除静音
        onMoved: {
            if (root.node) {
                if (isMuted) root.node.audio.muted = false 
                root.node.audio.volume = value
            }
        }

        // 轨道背景
        background: Item {
            x: control.leftPadding
            y: control.topPadding + control.availableHeight / 2 - height / 2
            width: control.availableWidth
            height: 16

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Qt.rgba(Appearance.colors.colOnLayer2.r, Appearance.colors.colOnLayer2.g, Appearance.colors.colOnLayer2.b, 0.1)
            }
            Rectangle {
                width: Math.max(0, control.visualPosition * parent.width)
                height: parent.height
                color: Appearance.colors.colPrimary
                radius: 8
            }
        }

        // 拖拽手柄与气泡
        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + control.availableHeight / 2 - height / 2
            width: 4
            height: 32
            radius: 2
            color: Appearance.colors.colOnLayer2

            
        }
    }
}
