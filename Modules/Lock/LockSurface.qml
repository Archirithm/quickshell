import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Common

Item {
    id: root

    property var context: null
    property var screenRef: null
    property real animProgress: 0
    property real backgroundOpacity: 0
    property bool isExiting: false

    readonly property real availableWidth: Math.max(1, width - Sizes.lockOuterPadding * 2)
    readonly property real workHeight: Math.max(1, height * Sizes.lockHeightMult)
    readonly property real targetHeight: Math.min(workHeight, availableWidth / Sizes.lockRatio)
    readonly property real targetWidth: targetHeight * Sizes.lockRatio
    readonly property real iconSize: Math.min(Sizes.lockIconPanelSize, targetHeight)
    readonly property real iconRadius: iconSize / 4
    readonly property real panelRadius: Sizes.lockCardRadiusLarge * 1.5

    function focusAuth() {
        lockContent.forceAuthFocus();
    }

    function startExitAnimation() {
        if (isExiting)
            return;

        isExiting = true;
        exitAnim.start();
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        z: -2
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        z: -1
        source: Paths.fileUrl(Paths.currentWallpaper)
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blurMax: 64
        blur: 1
        opacity: root.backgroundOpacity
    }

    ScreencopyView {
        id: liveBackground
        anchors.fill: parent
        captureSource: root.screenRef
        opacity: root.backgroundOpacity
        visible: root.screenRef !== null

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            blurMultiplier: 1
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.focusAuth()
    }

    Connections {
        target: root.context
        ignoreUnknownSignals: true

        function onUnlockSucceeded() {
            root.startExitAnimation();
        }

        function onUnlockFailed() {
            root.isExiting = false;
            root.focusAuth();
        }
    }

    ParallelAnimation {
        id: startupAnim
        running: true

        NumberAnimation {
            target: root
            property: "backgroundOpacity"
            to: 1
            duration: Appearance.animation.expressiveDefaultSpatial.duration
            easing.type: Appearance.animation.expressiveDefaultSpatial.type
            easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
        }

        SequentialAnimation {
            PauseAnimation { duration: 80 }
            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "animProgress"
                    to: 1
                    duration: Appearance.animation.expressiveDefaultSpatial.duration
                    easing.type: Appearance.animation.expressiveDefaultSpatial.type
                    easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
                }
                NumberAnimation {
                    target: lockIcon
                    property: "rotation"
                    from: 180
                    to: 360
                    duration: Appearance.animation.expressiveFastSpatial.duration
                    easing.type: Appearance.animation.expressiveFastSpatial.type
                    easing.bezierCurve: Appearance.animation.expressiveFastSpatial.bezierCurve
                }
            }
        }

        onFinished: root.focusAuth()
    }

    Rectangle {
        id: morphContainer
        anchors.centerIn: parent
        clip: true

        width: root.iconSize + (root.targetWidth - root.iconSize) * root.animProgress
        height: root.iconSize + (root.targetHeight - root.iconSize) * root.animProgress
        radius: root.iconRadius + (root.panelRadius - root.iconRadius) * root.animProgress
        color: Appearance.colors.colLayer0

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Appearance.colors.colShadow
            shadowBlur: 0.8
            shadowVerticalOffset: 8
        }

        Text {
            id: lockIcon
            anchors.centerIn: parent
            text: "lock"
            opacity: 1 - root.animProgress
            scale: 1 - root.animProgress * 0.45
            visible: opacity > 0
            color: Appearance.colors.colOnSurface
            font.family: "Material Symbols Rounded"
            font.pixelSize: root.iconSize * 0.56
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        LockContent {
            id: lockContent
            anchors.fill: parent
            anchors.margins: Sizes.lockOuterPadding
            context: root.context
            screenHeight: root.height
            opacity: root.animProgress > 0.5 ? (root.animProgress - 0.5) * 2 : 0
            scale: 0.86 + root.animProgress * 0.14
            visible: opacity > 0
        }
    }

    SequentialAnimation {
        id: exitAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "animProgress"
                to: 0
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
            }
            NumberAnimation {
                target: lockIcon
                property: "rotation"
                to: 180
                duration: Appearance.animation.expressiveFastSpatial.duration
                easing.type: Appearance.animation.expressiveFastSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveFastSpatial.bezierCurve
            }
            NumberAnimation {
                target: root
                property: "backgroundOpacity"
                to: 0
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
            }
        }

        NumberAnimation {
            target: morphContainer
            property: "opacity"
            to: 0
            duration: Appearance.animation.expressiveEffects.duration
            easing.type: Appearance.animation.expressiveEffects.type
            easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
        }

        onFinished: {
            if (root.context)
                root.context.finishUnlock();
        }
    }
}
