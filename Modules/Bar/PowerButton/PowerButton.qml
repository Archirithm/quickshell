import QtQuick
import Quickshell
import qs.config

Rectangle {
    id: root

    // 警告红
    color: Appearance.colors.colError 
    radius: height / 2
    implicitHeight: 28
    implicitWidth: 28

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["wlogout", "-p", "layer-shell", "-b", "2"])
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "⏻"
        font.pixelSize: 14 
        font.bold: true
        color: Appearance.colors.colOnError 
    }
}
