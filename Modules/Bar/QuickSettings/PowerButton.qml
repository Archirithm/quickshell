import QtQuick
import Quickshell
import qs.config

Rectangle {
    id: root
    property bool isHovered: mouseArea.containsMouse

    color: Colorscheme.error
    radius: height / 2
    implicitHeight: isHovered ? 34 : 28
    implicitWidth: isHovered ? 34 : 28

    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["wlogout", "-p", "layer-shell", "-b", "2"])
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "⏻"
        font.pixelSize: root.isHovered ? 16 : 14
        font.bold: true
        color: Colorscheme.on_error 
        Behavior on font.pixelSize { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
}
