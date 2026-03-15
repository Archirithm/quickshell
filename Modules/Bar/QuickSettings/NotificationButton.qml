import QtQuick
import Quickshell
import qs.config
import qs.Widget

Rectangle {
    id: root

    // 赋予次要强调色
    color: Colorscheme.secondary_container 
    radius: height / 2
    implicitHeight: 28
    implicitWidth: 28

    NotificationWidget { id: notifPanel; isOpen: false }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: notifPanel.isOpen = !notifPanel.isOpen
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: "\uf0f3" 
        font.family: "Font Awesome 6 Free Solid"
        font.pixelSize: 12 // 缩小以适应 28 的圆
        color: Colorscheme.on_secondary_container 
    }
}
