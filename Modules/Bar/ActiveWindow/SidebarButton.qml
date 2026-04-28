import QtQuick
import QtQuick.Effects
import qs.config

Item {
    id: root

    implicitWidth: 36
    implicitHeight: 36
    scale: mouseArea.containsMouse ? 1.08 : 1.0

    Behavior on scale {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: Colorscheme.background
        radius: width / 2
        visible: false
    }

    MultiEffect {
        source: bgRect
        anchors.fill: bgRect
        shadowEnabled: true
        shadowColor: Qt.alpha(Colorscheme.shadow, 0.4)
        shadowBlur: 0.8
        shadowVerticalOffset: 3
        shadowHorizontalOffset: 0
    }

    Item {
        width: 18
        height: 18
        anchors.centerIn: parent

        Text {
            anchors.centerIn: parent
            text: WidgetState.leftSidebarOpen ? "left_panel_close" : "left_panel_open"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 22
            color: Colorscheme.primary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: WidgetState.leftSidebarOpen = !WidgetState.leftSidebarOpen
    }
}
