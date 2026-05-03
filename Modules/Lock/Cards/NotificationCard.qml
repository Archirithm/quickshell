import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config
import qs.Services

Rectangle {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    color: Appearance.colors.colLayer2
    radius: Sizes.lockCardRadius
    clip: true

    readonly property var notifications: NotificationManager.list.slice().sort((a, b) => b.time - a.time)
    readonly property int notificationCount: notifications.length

    function normalizeSource(source) {
        if (!source || source === "")
            return "";
        if (source.startsWith("/"))
            return "file://" + source;
        return source;
    }

    function iconSourceFor(notificationObject) {
        if (!notificationObject)
            return "";
        if (notificationObject.image && notificationObject.image !== "")
            return normalizeSource(notificationObject.image);
        if (notificationObject.appIcon && notificationObject.appIcon !== "") {
            if (notificationObject.appIcon.startsWith("/") || notificationObject.appIcon.startsWith("file://"))
                return normalizeSource(notificationObject.appIcon);
            return Quickshell.iconPath(notificationObject.appIcon, "image-missing");
        }
        return "";
    }

    function formatTime(timestamp) {
        const date = new Date(Number(timestamp));
        if (isNaN(date.getTime()))
            return "";

        const now = new Date();
        if (date.toDateString() === now.toDateString())
            return Qt.formatTime(date, "HH:mm");
        return Qt.formatDate(date, "MM/dd") + " " + Qt.formatTime(date, "HH:mm");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Notifications"
                color: Appearance.colors.colOnSurfaceVariant
                font.family: Sizes.fontFamilyMono
                font.pixelSize: 12
                font.bold: true
            }

            Rectangle {
                visible: root.notificationCount > 0
                width: countText.contentWidth + 12
                height: 18
                radius: 9
                color: Appearance.colors.colPrimaryContainer

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: root.notificationCount
                    color: Appearance.colors.colOnPrimaryContainer
                    font.family: Sizes.fontFamilyMono
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Clear All"
                visible: root.notificationCount > 0
                color: Appearance.colors.colPrimary
                font.family: Sizes.fontFamilyMono
                font.pixelSize: 12
                font.underline: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationManager.discardAllNotifications()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.colors.colOutline
            opacity: 0.2
        }

        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 12
            model: root.notifications

            Text {
                anchors.centerIn: parent
                visible: root.notificationCount === 0
                text: "No new notifications"
                color: Appearance.colors.colOnSurfaceVariant
                font.family: Sizes.fontFamily
                font.pixelSize: 14
                opacity: 0.5
            }

            delegate: Rectangle {
                id: delegateRoot

                required property var modelData

                width: ListView.view ? ListView.view.width : 0
                height: Math.max(68, contentRow.implicitHeight)
                color: "transparent"

                readonly property string iconSource: root.iconSourceFor(modelData)

                RowLayout {
                    id: contentRow
                    anchors.fill: parent
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        Layout.alignment: Qt.AlignTop
                        radius: 13
                        color: Appearance.colors.colLayer4
                        clip: true

                        Image {
                            id: iconImg
                            anchors.fill: parent
                            anchors.margins: delegateRoot.modelData && delegateRoot.modelData.image ? 0 : 6
                            source: delegateRoot.iconSource
                            fillMode: delegateRoot.modelData && delegateRoot.modelData.image ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                            visible: delegateRoot.iconSource !== "" && status !== Image.Error
                            asynchronous: true
                            smooth: true
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "notifications"
                            visible: !iconImg.visible
                            color: Appearance.colors.colOnSurfaceVariant
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 20
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: delegateRoot.modelData ? delegateRoot.modelData.appName : ""
                                color: Appearance.colors.colPrimary
                                font.family: Sizes.fontFamilyMono
                                font.pixelSize: 10
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: delegateRoot.modelData ? root.formatTime(delegateRoot.modelData.time) : ""
                                color: Appearance.colors.colOnSurfaceVariant
                                font.family: Sizes.fontFamilyMono
                                font.pixelSize: 10
                                opacity: 0.7
                            }
                        }

                        Text {
                            text: delegateRoot.modelData ? delegateRoot.modelData.summary : ""
                            color: Appearance.colors.colOnSurface
                            font.family: Sizes.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: delegateRoot.modelData ? delegateRoot.modelData.body : ""
                            color: Appearance.colors.colOnSurfaceVariant
                            font.family: Sizes.fontFamily
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            maximumLineCount: 2
                            opacity: 0.8
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignTop
                        text: "close"
                        color: Appearance.colors.colOnSurfaceVariant
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationManager.discardNotification(delegateRoot.modelData.notificationId)
                        }
                    }
                }
            }

            add: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Appearance.animation.expressiveEffects.duration
                        easing.type: Appearance.animation.expressiveEffects.type
                        easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                    }
                    NumberAnimation {
                        property: "y"
                        from: -20
                        duration: Appearance.animation.expressiveEffects.duration
                        easing.type: Appearance.animation.expressiveEffects.type
                        easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                    }
                }
            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "opacity"
                        to: 0
                        duration: Appearance.animation.expressiveEffects.duration
                        easing.type: Appearance.animation.expressiveEffects.type
                        easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                    }
                    NumberAnimation {
                        property: "height"
                        to: 0
                        duration: Appearance.animation.expressiveEffects.duration
                        easing.type: Appearance.animation.expressiveEffects.type
                        easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                    }
                }
            }
        }
    }
}
