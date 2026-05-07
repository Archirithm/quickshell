import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Services
import qs.Common
import qs.Widgets.common

Item {
    id: root
    property bool isHovered: mouseArea.containsMouse

    implicitHeight: 28
    implicitWidth: isHovered ? layout.implicitWidth : 28

    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        // 圆弧仪表盘
        ArcGauge {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28

            value: Volume.sinkVolume
            progressColor: (Volume.sinkMuted || Volume.sinkVolume <= 0) ? Appearance.colors.colError : Appearance.colors.colPrimary
            trackColor: Appearance.colors.colLayer2Hover
            handleColor: Appearance.colors.colOnSurface
            iconColor: (Volume.sinkMuted || Volume.sinkVolume <= 0) ? Appearance.colors.colError : Appearance.colors.colOnSurface

            icon: {
                if (Volume.isHeadphone) return "headphones"
                if (Volume.sinkMuted || Volume.sinkVolume <= 0) return "volume_off"
                if (Volume.sinkVolume < 0.5) return "volume_down"
                return "volume_up"
            }
        }

        // 音量数字（hover 时展开）
        Text {
            id: volText
            text: Math.round(Volume.sinkVolume * 100).toString()
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: true
            color: Appearance.colors.colOnSurface
            visible: root.isHovered
            opacity: root.isHovered ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onWheel: (wheel) => {
            const step = 0.05
            let newVol = Volume.sinkVolume
            if (wheel.angleDelta.y > 0) newVol += step
            else newVol -= step
            Volume.setSinkVolume(newVol)
        }
        onClicked: {
            if (WidgetState.qsOpen && WidgetState.qsView === "audio") {
                WidgetState.qsOpen = false;
            } else {
                WidgetState.qsView = "audio";
                WidgetState.qsOpen = true;
            }
        }
    }
}
