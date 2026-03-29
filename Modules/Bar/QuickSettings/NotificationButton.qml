import QtQuick
import Quickshell
import qs.config

Rectangle {
    id: root
    color: Colorscheme.secondary_container 
    radius: height / 2
    implicitHeight: 28
    implicitWidth: 28

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: WidgetState.notifOpen = !WidgetState.notifOpen
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "\uf0f3" 
        font.family: "Font Awesome 6 Free Solid"
        font.pixelSize: 12
        color: Colorscheme.on_secondary_container 
    }
}
