import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Services
import qs.config

// 1. 导入 Widget 目录
import qs.Widget

Rectangle {
    id: root

    // --- 样式配置 ---
    color: Colorsheme.background
    radius: Sizes.cornerRadius
    implicitHeight: Sizes.barHeight
    implicitWidth: layout.width + 24

    // 2. 实例化混音器小组件
    AudioWidget {
        id: audioPanel
        isOpen: false // 默认关闭
    }

    // --- 交互区域 ---
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        
        // 允许滚轮调节音量 (保持不变)
        onWheel: (wheel) => {
            const step = 0.05
            let newVol = Volume.sinkVolume
            
            if (wheel.angleDelta.y > 0) newVol += step
            else newVol -= step

            Volume.setSinkVolume(newVol)
        }

        // 3. 点击切换小组件开关
        onClicked: {
            // 原来是: Quickshell.execDetached(["pavucontrol"])
            // 现在改为:
            audioPanel.isOpen = !audioPanel.isOpen
        }
    }

    // --- 内容布局 (保持不变) ---
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        Text {
            // font.family: "Font Awesome 6 Free Regular" 
            font.pixelSize: 16
            color: (Volume.sinkMuted || Volume.sinkVolume <= 0) ? "#ff5555" : Colorsheme.on_tertiary_container
            text: {
                if (Volume.isHeadphone) return ""
                if (Volume.sinkMuted || Volume.sinkVolume <= 0) return ""
                if (Volume.sinkVolume < 0.5) return ""
                return ""
            }
        }

        Text {
            font.bold: true
            font.pixelSize: 14
            color: Colorsheme.on_primary_container
            text: Math.round(Volume.sinkVolume * 100) + "%"
        }
    }
}
