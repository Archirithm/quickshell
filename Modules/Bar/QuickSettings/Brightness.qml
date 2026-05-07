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

            value: Brightness.brightnessValue
            progressColor: Appearance.colors.colPrimary
            trackColor: Appearance.colors.colLayer2Hover
            handleColor: Appearance.colors.colOnSurface
            iconColor: Appearance.colors.colOnSurface

            // Material Symbols: brightness_medium
            icon: "brightness_medium"
        }

        // 亮度数字（hover 时展开）
        Text {
            id: briText
            text: Math.round(Brightness.brightnessValue * 100).toString()
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
            let newBri = Brightness.brightnessValue
            if (wheel.angleDelta.y > 0) newBri += step
            else newBri -= step
            Brightness.setBrightness(newBri)
        }
    }
}
