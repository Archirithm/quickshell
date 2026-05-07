import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.Common

Item {
    id: root

    property string appIcon: ""
    property string summary: ""
    property string image: ""
    property string urgency: NotificationUrgency.Normal.toString()
    property bool imageLoaded: false
    property bool imageLoadFailed: false
    property bool appIconLoadFailed: false
    readonly property bool isUrgent: urgency === NotificationUrgency.Critical.toString()
    readonly property bool appIconIsFile: appIcon.startsWith("file://") || appIcon.startsWith("/")
    readonly property string cleanFileAppIcon: appIcon.startsWith("/") ? "file://" + appIcon : appIcon
    readonly property bool hasImage: image !== "" && !image.startsWith("icon:")
    readonly property bool hasAppIcon: appIcon !== ""
    readonly property string appIconSource: !hasAppIcon ? "" : appIconIsFile ? cleanFileAppIcon : resolvedIconSource(appIcon)
    readonly property bool showImage: hasImage && imageLoaded && !imageLoadFailed
    readonly property bool showFallback: !showImage
    readonly property bool showAppIcon: showFallback && hasAppIcon && !appIconLoadFailed
    readonly property bool showSymbol: showFallback && (!hasAppIcon || appIconLoadFailed)
    readonly property real materialIconSize: implicitWidth * 0.6
    readonly property real appIconSize: implicitWidth * 0.8
    readonly property real smallAppIconSize: implicitWidth * 0.42

    implicitWidth: 38
    implicitHeight: 38

    NotificationUtils { id: notifUtils }

    onImageChanged: {
        imageLoaded = false;
        imageLoadFailed = false;
    }

    onAppIconChanged: appIconLoadFailed = false

    function resolvedIconSource(iconName) {
        const iconPath = Quickshell.iconPath(iconName, "image-missing");
        if (iconPath && iconPath !== "")
            return iconPath;
        return "image://icon/" + iconName;
    }

    Rectangle {
        id: base
        anchors.fill: parent
        radius: root.isUrgent ? 14 : width / 2
        color: root.isUrgent ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer
    }

    Text {
        anchors.centerIn: parent
        visible: root.showSymbol
        text: root.isUrgent ? "priority_high" : notifUtils.findSuitableMaterialSymbol(root.summary)
        font.family: "Material Symbols Rounded"
        font.pixelSize: root.materialIconSize
        color: root.isUrgent ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
    }

    Loader {
        active: root.showAppIcon
        anchors.centerIn: parent
        width: root.appIconSize
        height: root.appIconSize
        sourceComponent: appIconComponent
    }

    Loader {
        active: root.hasImage && !root.imageLoadFailed
        anchors.fill: parent
        sourceComponent: imageComponent
    }

    Component {
        id: appIconComponent

        Image {
            width: root.appIconSize
            height: root.appIconSize
            source: root.appIconSource
            sourceSize.width: root.appIconSize
            sourceSize.height: root.appIconSize
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            onStatusChanged: root.appIconLoadFailed = status === Image.Error
        }
    }

    Component {
        id: imageComponent

        Item {
            anchors.fill: parent

            Image {
                id: notifImage
                anchors.fill: parent
                source: root.image
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: false
                onStatusChanged: {
                    root.imageLoaded = status === Image.Ready;
                    root.imageLoadFailed = status === Image.Error;
                }
            }

            Rectangle {
                id: imageMask
                anchors.fill: parent
                radius: width / 2
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: notifImage
                maskSource: imageMask
            }

            Rectangle {
                width: 17
                height: 17
                radius: 8.5
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: Appearance.colors.colLayer4
                visible: root.hasAppIcon

                Loader {
                    anchors.centerIn: parent
                    width: 13
                    height: 13
                    active: root.hasAppIcon && !root.appIconLoadFailed
                    sourceComponent: smallAppIconComponent
                }
            }
        }
    }

    Component {
        id: smallAppIconComponent

        Image {
            width: root.smallAppIconSize
            height: root.smallAppIconSize
            source: root.appIconSource
            sourceSize.width: root.smallAppIconSize
            sourceSize.height: root.smallAppIconSize
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
    }
}
