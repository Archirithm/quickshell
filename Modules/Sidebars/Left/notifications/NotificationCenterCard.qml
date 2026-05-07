import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services

Rectangle {
    id: root

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    clip: true

    NotificationListView {
        id: listView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: statusRow.top
        anchors.margins: 5
        anchors.bottomMargin: 8
    }

    Column {
        anchors.centerIn: listView
        spacing: 6
        visible: NotificationManager.list.length === 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "notifications_active"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 34
            color: Appearance.colors.colOnSurfaceVariant
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nothing"
            font.family: Sizes.fontFamily
            font.pixelSize: 14
            font.bold: true
            color: Appearance.colors.colOnSurfaceVariant
        }
    }

    RowLayout {
        id: statusRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 5
        spacing: 5

        NotificationStatusButton {
            Layout.fillWidth: false
            buttonIcon: "notifications_paused"
            toggled: NotificationManager.silent
            onClicked: NotificationManager.setSilent(!NotificationManager.silent)
        }

        NotificationStatusButton {
            Layout.fillWidth: true
            enabled: false
            buttonText: `${NotificationManager.list.length} notifications`
        }

        NotificationStatusButton {
            Layout.fillWidth: false
            buttonIcon: "delete_sweep"
            onClicked: NotificationManager.discardAllNotifications()
        }
    }
}
