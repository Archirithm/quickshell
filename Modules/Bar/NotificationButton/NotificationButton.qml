import QtQuick
import Quickshell
import qs.config
import qs.Widget

Rectangle {
        id: root

        color: Colorscheme.on_primary_container 
        radius: Sizes.cornerRadius
        implicitHeight: Sizes.barHeight
        implicitWidth: icon.contentWidth + 20

        NotificationWidget {
                id: notifPanel
                isOpen: false
                // 在你的 NotificationWidget 内部，务必让它读取 NotificationManager.historyModel
        }

        MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                
                onClicked: {
                        notifPanel.isOpen = !notifPanel.isOpen
                }
        }

        Text {
                id: icon
                anchors.centerIn: parent
                text: "\uf0f3" 
                font.family: "Font Awesome 6 Free Solid"
                font.pixelSize: 15
                font.bold: true
                color: Colorscheme.background 
        }
}
