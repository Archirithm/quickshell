import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import qs.Common

Item {
    id: root

    property var context: null
    property var screenRef: null
    property bool isExiting: false
    property real backgroundOpacity: 1
    property real morphProgress: 0
    property real containerScale: 0
    property real containerRotation: 180
    property real contentOpacity: 0
    property real contentScale: 0

    readonly property real targetHeight: Math.max(1, height * Sizes.lockHeightMult)
    readonly property real targetWidth: targetHeight * Sizes.lockRatio
    readonly property real compactSize: Math.min(Sizes.lockIconPanelSize, targetHeight)
    readonly property real compactRadius: compactSize / 4
    readonly property real panelRadius: Sizes.lockCardRadiusLarge * 1.5

    function focusAuth() {
        if (lockContent.opacity > 0)
            lockContent.forceAuthFocus();
    }

    function startExitAnimation() {
        if (isExiting)
            return;

        startupAnim.stop();
        isExiting = true;
        exitAnim.start();
    }

    function emergencyExit() {
        if (!root.context)
            return;

        startupAnim.stop();
        exitAnim.stop();
        root.isExiting = true;
        root.context.finishUnlock();
    }

    ScreencopyView {
        id: desktopBackdrop
        anchors.fill: parent
        captureSource: root.screenRef
        opacity: root.screenRef !== null ? 1 : 0
        visible: root.screenRef !== null
    }

    ScreencopyView {
        id: background
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

    Rectangle {
        id: emergencyExitButton
        z: 1000
        width: Math.max(230, emergencyExitLabel.implicitWidth + 32)
        height: 42
        radius: 12
        color: emergencyExitMouse.containsMouse ? Appearance.colors.colErrorContainerHover : Appearance.colors.colErrorContainer
        border.width: 1
        border.color: Appearance.colors.colError

        anchors {
            top: parent.top
            left: parent.left
            margins: Sizes.lockOuterPadding
        }

        Text {
            id: emergencyExitLabel
            anchors.centerIn: parent
            text: "Its not working, let me out"
            color: Appearance.colors.colOnErrorContainer
            font.family: Sizes.fontFamily
            font.pixelSize: 14
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            id: emergencyExitMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.emergencyExit()
        }
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
        onFinished: root.focusAuth()

        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "containerScale"
                    to: 1
                    duration: Appearance.animation.expressiveFastSpatial.duration
                    easing.type: Appearance.animation.expressiveFastSpatial.type
                    easing.bezierCurve: Appearance.animation.expressiveFastSpatial.bezierCurve
                }

                NumberAnimation {
                    target: root
                    property: "containerRotation"
                    to: 360
                    duration: Appearance.animation.expressiveFastSpatial.duration
                    easing.type: Appearance.animation.standardAccel.type
                    easing.bezierCurve: Appearance.animation.standardAccel.bezierCurve
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "morphProgress"
                    to: 1
                    duration: Appearance.animation.expressiveDefaultSpatial.duration
                    easing.type: Appearance.animation.expressiveDefaultSpatial.type
                    easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
                }

                NumberAnimation {
                    target: lockIcon
                    property: "rotation"
                    to: 360
                    duration: Appearance.animation.standard.duration
                    easing.type: Appearance.animation.standardDecel.type
                    easing.bezierCurve: Appearance.animation.standardDecel.bezierCurve
                }

                NumberAnimation {
                    target: lockIcon
                    property: "opacity"
                    to: 0
                    duration: Appearance.animation.standard.duration
                    easing.type: Appearance.animation.standard.type
                    easing.bezierCurve: Appearance.animation.standard.bezierCurve
                }

                NumberAnimation {
                    target: root
                    property: "contentOpacity"
                    to: 1
                    duration: Appearance.animation.standard.duration
                    easing.type: Appearance.animation.standard.type
                    easing.bezierCurve: Appearance.animation.standard.bezierCurve
                }

                NumberAnimation {
                    target: root
                    property: "contentScale"
                    to: 1
                    duration: Appearance.animation.expressiveDefaultSpatial.duration
                    easing.type: Appearance.animation.expressiveDefaultSpatial.type
                    easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
                }
            }
        }
    }

    Rectangle {
        id: morphContainer
        anchors.centerIn: parent
        clip: true

        width: root.compactSize + (root.targetWidth - root.compactSize) * root.morphProgress
        height: root.compactSize + (root.targetHeight - root.compactSize) * root.morphProgress
        radius: root.compactRadius + (root.panelRadius - root.compactRadius) * root.morphProgress
        rotation: root.containerRotation
        scale: root.containerScale
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
            rotation: 180
            color: Appearance.colors.colOnSurface
            font.family: "Material Symbols Rounded"
            font.pixelSize: root.compactSize * 0.56
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        LockContent {
            id: lockContent
            anchors.centerIn: parent
            width: root.targetWidth - Sizes.lockOuterPadding * 2
            height: root.targetHeight - Sizes.lockOuterPadding * 2
            context: root.context
            screenHeight: root.height
            opacity: root.contentOpacity
            scale: root.contentScale
            visible: opacity > 0 || root.morphProgress > 0.96
        }
    }

    SequentialAnimation {
        id: exitAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "morphProgress"
                to: 0
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
            }

            NumberAnimation {
                target: root
                property: "contentScale"
                to: 0
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
            }

            NumberAnimation {
                target: root
                property: "contentOpacity"
                to: 0
                duration: Appearance.animation.standardSmall.duration
                easing.type: Appearance.animation.standardSmall.type
                easing.bezierCurve: Appearance.animation.standardSmall.bezierCurve
            }

            NumberAnimation {
                target: lockIcon
                property: "opacity"
                to: 1
                duration: Appearance.animation.standardLarge.duration
                easing.type: Appearance.animation.standardLarge.type
                easing.bezierCurve: Appearance.animation.standardLarge.bezierCurve
            }

            NumberAnimation {
                target: root
                property: "backgroundOpacity"
                to: 0
                duration: Appearance.animation.standardLarge.duration
                easing.type: Appearance.animation.standardLarge.type
                easing.bezierCurve: Appearance.animation.standardLarge.bezierCurve
            }

            NumberAnimation {
                target: lockIcon
                property: "rotation"
                to: 360
                duration: Appearance.animation.standard.duration
                easing.type: Appearance.animation.standardDecel.type
                easing.bezierCurve: Appearance.animation.standardDecel.bezierCurve
            }
        }

        SequentialAnimation {
            PauseAnimation { duration: Animations.durations.small }

            NumberAnimation {
                target: morphContainer
                property: "opacity"
                to: 0
                duration: Appearance.animation.expressiveEffects.duration
                easing.type: Appearance.animation.expressiveEffects.type
                easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
            }
        }

        onFinished: {
            if (root.context)
                root.context.finishUnlock();
        }
    }
}
