import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Notifications
import qs.Common
import qs.Services

Item {
    id: root

    property int delegateIndex: -1
    property var notificationObject
    property bool expanded: false
    property bool onlyNotification: false
    property real fontSize: 12
    property real padding: onlyNotification ? 0 : 8
    property real summaryElideRatio: 0.85
    property real dragConfirmThreshold: 70
    property real dismissOvershoot: notificationIcon.implicitWidth + 20
    property var dragHost
    property int parentDragIndex: dragHost ? dragHost.dragIndex : -1
    property real parentDragDistance: dragHost ? dragHost.dragDistance : 0
    property int dragIndexDiff: Math.abs(parentDragIndex - delegateIndex)
    property real xOffset: dragIndexDiff === 0 ? parentDragDistance
        : Math.abs(parentDragDistance) > dragConfirmThreshold ? 0
        : dragIndexDiff === 1 ? parentDragDistance * 0.3
        : dragIndexDiff === 2 ? parentDragDistance * 0.1
        : 0

    signal clicked()

    implicitHeight: background.implicitHeight

    NotificationUtils { id: notifUtils }

    TextMetrics {
        id: summaryTextMetrics
        font.pixelSize: root.fontSize
        text: root.notificationObject ? root.notificationObject.summary : ""
    }

    function destroyWithAnimation(left = false) {
        background.anchors.leftMargin = background.anchors.leftMargin;
        if (root.dragHost)
            root.dragHost.resetDrag();
        dragManager.resetDrag();
        destroyAnimation.left = left;
        destroyAnimation.running = true;
    }

    SequentialAnimation {
        id: destroyAnimation
        property bool left: true
        running: false

        NumberAnimation {
            target: background.anchors
            property: "leftMargin"
            to: (root.width + root.dismissOvershoot) * (destroyAnimation.left ? -1 : 1)
            duration: Appearance.animation.expressiveDefaultSpatial.duration
            easing.type: Appearance.animation.expressiveDefaultSpatial.type
            easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
        }

        onFinished: NotificationManager.discardNotification(root.notificationObject.notificationId)
    }

    DragManager {
        id: dragManager
        anchors.fill: root
        anchors.leftMargin: root.expanded ? -notificationIcon.implicitWidth : 0
        interactive: root.expanded && !root.onlyNotification
        automaticallyReset: false
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton)
                root.destroyWithAnimation();
        }

        onDraggingChanged: {
            if (dragging && root.dragHost)
                root.dragHost.dragIndex = root.delegateIndex;
        }

        onDragDiffXChanged: {
            if (root.dragHost)
                root.dragHost.dragDistance = dragDiffX;
        }

        onDragReleased: (diffX) => {
            if (Math.abs(diffX) > root.dragConfirmThreshold)
                root.destroyWithAnimation(diffX < 0);
            else {
                dragManager.resetDrag();
                if (root.dragHost)
                    root.dragHost.resetDrag();
            }
        }
    }

    NotificationAppIcon {
        id: notificationIcon
        opacity: (!root.onlyNotification && root.notificationObject && root.notificationObject.image !== "" && root.expanded) ? 1 : 0
        visible: opacity > 0
        image: root.notificationObject ? root.notificationObject.image : ""
        appIcon: root.notificationObject ? root.notificationObject.appIcon : ""
        summary: root.notificationObject ? root.notificationObject.summary : ""
        urgency: root.notificationObject ? root.notificationObject.urgency : NotificationUrgency.Normal.toString()
        anchors.right: background.left
        anchors.top: background.top
        anchors.rightMargin: 10

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.expressiveEffects.duration
                easing.type: Appearance.animation.expressiveEffects.type
                easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
            }
        }
    }

    Rectangle {
        id: background
        width: parent.width
        anchors.left: parent.left
        anchors.leftMargin: root.xOffset
        radius: Appearance.rounding.small
        color: (root.expanded && !root.onlyNotification)
            ? (root.notificationObject && root.notificationObject.urgency === NotificationUrgency.Critical.toString()
                ? Appearance.mix(Appearance.colors.colSecondaryContainer, Appearance.colors.colLayer2, 0.35)
                : Appearance.colors.colLayer3)
            : "transparent"
        implicitHeight: root.expanded ? contentColumn.implicitHeight + root.padding * 2 : summaryRow.implicitHeight

        Behavior on anchors.leftMargin {
            enabled: !dragManager.dragging && !destroyAnimation.running
            NumberAnimation {
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveFastSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveFastSpatial.bezierCurve
            }
        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
            }
        }

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: root.expanded ? root.padding : 0
                spacing: 3

            Behavior on anchors.margins {
                NumberAnimation {
                    duration: Appearance.animation.expressiveEffects.duration
                    easing.type: Appearance.animation.expressiveEffects.type
                    easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                }
            }

            RowLayout {
                id: summaryRow
                visible: !root.onlyNotification || !root.expanded
                Layout.fillWidth: true
                implicitHeight: summaryText.implicitHeight

                Text {
                    id: summaryText
                    visible: !root.onlyNotification
                    Layout.fillWidth: summaryTextMetrics.width >= summaryRow.implicitWidth * root.summaryElideRatio
                    text: root.notificationObject ? root.notificationObject.summary : ""
                    font.family: Sizes.fontFamily
                    font.pixelSize: root.fontSize
                    font.bold: true
                    color: Appearance.colors.colOnLayer3
                    elide: Text.ElideRight
                }

                Text {
                    id: bodyPreview
                    visible: opacity > 0
                    opacity: !root.expanded ? 1 : 0
                    Layout.fillWidth: true
                    text: notifUtils.processNotificationBody(root.notificationObject ? root.notificationObject.body : "", root.notificationObject ? root.notificationObject.appName : "").replace(/\n/g, "<br/>")
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    font.family: Sizes.fontFamily
                    font.pixelSize: root.fontSize
                    color: Appearance.colors.colSubtext

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.animation.expressiveEffects.duration
                            easing.type: Appearance.animation.expressiveEffects.type
                            easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                        }
                    }
                }
            }

            ColumnLayout {
                id: expandedContentColumn
                Layout.fillWidth: true
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.expressiveEffects.duration
                        easing.type: Appearance.animation.expressiveEffects.type
                        easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: `<style>img{max-width:${expandedContentColumn.width}px;}</style>` +
                        notifUtils.processNotificationBody(root.notificationObject ? root.notificationObject.body : "", root.notificationObject ? root.notificationObject.appName : "").replace(/\n/g, "<br/>")
                    textFormat: Text.RichText
                    wrapMode: Text.Wrap
                    font.family: Sizes.fontFamily
                    font.pixelSize: root.fontSize
                    color: Appearance.colors.colSubtext
                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                }

                Item {
                    id: actionsContainer
                    Layout.fillWidth: true
                    implicitWidth: actionsFlickable.implicitWidth
                    implicitHeight: actionsFlickable.implicitHeight
                    clip: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: actionsFlickable.width
                            height: actionsFlickable.height
                            radius: Appearance.rounding.small
                        }
                    }

                    Flickable {
                        id: actionsFlickable
                        anchors.fill: parent
                        implicitHeight: actionRow.implicitHeight
                        contentWidth: actionRow.implicitWidth
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.HorizontalFlick
                        clip: true

                        Behavior on height {
                            NumberAnimation {
                                duration: Appearance.animation.expressiveEffects.duration
                                easing.type: Appearance.animation.expressiveEffects.type
                                easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                            }
                        }

                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: Appearance.animation.expressiveEffects.duration
                                easing.type: Appearance.animation.expressiveEffects.type
                                easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                            }
                        }

                        RowLayout {
                            id: actionRow
                            spacing: 6

                            NotificationActionButton {
                                buttonText: root.notificationObject && root.notificationObject.actions.length > 0 ? "" : "Close"
                                iconName: root.notificationObject && root.notificationObject.actions.length > 0 ? "close" : ""
                                urgency: root.notificationObject ? root.notificationObject.urgency : NotificationUrgency.Normal.toString()
                                onClicked: root.destroyWithAnimation()
                            }

                            Repeater {
                                model: root.notificationObject ? root.notificationObject.actions : []

                                NotificationActionButton {
                                    required property var modelData
                                    buttonText: modelData.text
                                    urgency: root.notificationObject ? root.notificationObject.urgency : NotificationUrgency.Normal.toString()
                                    onClicked: NotificationManager.attemptInvokeAction(root.notificationObject.notificationId, modelData.identifier)
                                }
                            }

                            NotificationActionButton {
                                iconName: "content_copy"
                                urgency: root.notificationObject ? root.notificationObject.urgency : NotificationUrgency.Normal.toString()
                                onClicked: {
                                    Quickshell.clipboardText = root.notificationObject ? root.notificationObject.body : "";
                                    iconName = "inventory";
                                    copyIconTimer.restart();
                                }

                                Timer {
                                    id: copyIconTimer
                                    interval: 1500
                                    repeat: false
                                    onTriggered: parent.iconName = "content_copy"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
