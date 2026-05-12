import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.Common

FocusScope {
    id: root

    property var context: null
    readonly property bool hasText: input.text.length > 0
    readonly property bool busy: context && context.unlockInProgress

    signal requestUnlock()

    Layout.fillWidth: true
    Layout.preferredHeight: Sizes.lockAuthHeight

    Component.onCompleted: input.forceActiveFocus()
    onActiveFocusChanged: if (activeFocus) input.forceActiveFocus()

    Rectangle {
        id: inputFrame

        anchors.fill: parent
        color: Appearance.colors.colLayer2
        radius: height / 2
        clip: true

        Rectangle {
            id: ripple

            property real centerX: 0
            property real centerY: 0
            property real rippleSize: Math.max(inputFrame.width, inputFrame.height) * 2.2

            function start(x, y) {
                centerX = x;
                centerY = y;
                scale = 0;
                opacity = 0.14;
                rippleAnim.restart();
            }

            width: rippleSize
            height: rippleSize
            x: centerX - width / 2
            y: centerY - height / 2
            radius: width / 2
            color: Appearance.colors.colOnSurface
            opacity: 0
            scale: 0

            ParallelAnimation {
                id: rippleAnim

                NumberAnimation {
                    target: ripple
                    property: "scale"
                    to: 1
                    duration: Appearance.animation.expressiveDefaultSpatial.duration
                    easing.type: Appearance.animation.expressiveDefaultSpatial.type
                    easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
                }

                NumberAnimation {
                    target: ripple
                    property: "opacity"
                    to: 0
                    duration: Appearance.animation.expressiveEffects.duration
                    easing.type: Appearance.animation.expressiveEffects.type
                    easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Math.round(5 * 4 / 3)
            spacing: Math.round(12 * 4 / 3)

            Item {
                Layout.preferredWidth: Math.round(38 * 4 / 3)
                Layout.fillHeight: true

                Item {
                    id: progressHost

                    anchors.centerIn: parent
                    width: 32
                    height: 32

                    property real arcStart: -90
                    property real arcSweep: 78

                    Text {
                        id: lockIcon

                        anchors.centerIn: parent
                        text: "lock"
                        color: Appearance.colors.colOnSurface
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 24
                        opacity: root.busy ? 0 : 1

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Appearance.animation.expressiveEffects.duration
                                easing.type: Appearance.animation.expressiveEffects.type
                                easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                            }
                        }
                    }

                    Shape {
                        id: busyIndicator

                        anchors.fill: parent
                        opacity: root.busy ? 1 : 0

                        ShapePath {
                            strokeColor: Appearance.colors.colSecondary
                            strokeWidth: 3
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap

                            PathAngleArc {
                                centerX: busyIndicator.width / 2
                                centerY: busyIndicator.height / 2
                                radiusX: Math.max(1, busyIndicator.width / 2 - 2)
                                radiusY: Math.max(1, busyIndicator.height / 2 - 2)
                                startAngle: progressHost.arcStart
                                sweepAngle: progressHost.arcSweep
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Appearance.animation.expressiveEffects.duration
                                easing.type: Appearance.animation.expressiveEffects.type
                                easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                            }
                        }
                    }

                    SequentialAnimation {
                        running: root.busy
                        loops: Animation.Infinite

                        ParallelAnimation {
                            NumberAnimation {
                                target: progressHost
                                property: "arcStart"
                                from: -90
                                to: 270
                                duration: Appearance.animation.expressiveDefaultSpatial.duration
                                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
                            }
                            NumberAnimation {
                                target: progressHost
                                property: "arcSweep"
                                from: 62
                                to: 246
                                duration: Appearance.animation.expressiveDefaultSpatial.duration
                                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
                            }
                        }

                        ParallelAnimation {
                            NumberAnimation {
                                target: progressHost
                                property: "arcStart"
                                to: 630
                                duration: Appearance.animation.expressiveDefaultSpatial.duration
                                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
                            }
                            NumberAnimation {
                                target: progressHost
                                property: "arcSweep"
                                to: 62
                                duration: Appearance.animation.expressiveDefaultSpatial.duration
                                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextInput {
                    id: input

                    anchors.fill: parent
                    color: "transparent"
                    selectionColor: "transparent"
                    selectedTextColor: "transparent"
                    focus: true
                    cursorVisible: false
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    onActiveFocusChanged: cursorVisible = false
                    onCursorVisibleChanged: if (cursorVisible) cursorVisible = false

                    onAccepted: {
                        placeholder.animateOnNextShow = false;
                        if (!root.busy)
                            root.requestUnlock();
                    }

                    onTextChanged: {
                        if (root.context)
                            root.context.currentText = text;

                        if (text.length > dotsModel.count)
                            dotsList.bindImplicitWidth();
                        else if (text.length === 0)
                            placeholder.animateOnNextShow = true;

                        while (dotsModel.count < text.length)
                            dotsModel.append({});

                        while (dotsModel.count > text.length)
                            dotsModel.remove(dotsModel.count - 1);
                    }

                    Connections {
                        target: root.context
                        ignoreUnknownSignals: true

                        function onCurrentTextChanged() {
                            if (root.context && input.text !== root.context.currentText)
                                input.text = root.context.currentText;
                        }
                    }
                }

                Text {
                    id: placeholder

                    property bool animateOnNextShow: true

                    anchors.centerIn: parent
                    text: root.busy ? "Loading..." : "Enter your password"
                    color: root.busy ? Appearance.colors.colSecondary : Appearance.colors.colOutline
                    font.family: Sizes.fontFamilyMono
                    font.pixelSize: 17
                    opacity: root.hasText ? 0 : 1
                    scale: root.hasText ? 0.96 : 1

                    Behavior on opacity {
                        enabled: placeholder.animateOnNextShow
                        NumberAnimation {
                            duration: Appearance.animation.expressiveEffects.duration
                            easing.type: Appearance.animation.expressiveEffects.type
                            easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Appearance.animation.expressiveFastSpatial.duration
                            easing.type: Appearance.animation.expressiveFastSpatial.type
                            easing.bezierCurve: Appearance.animation.expressiveFastSpatial.bezierCurve
                        }
                    }
                }

                ListModel {
                    id: dotsModel
                }

                ListView {
                    id: dotsList

                    readonly property int fullWidth: count === 0 ? 0 : count * (dotSize + spacing) - spacing
                    property int dotSize: 17

                    function bindImplicitWidth() {
                        implicitWidthBehavior.enabled = false;
                        implicitWidth = Qt.binding(() => fullWidth);
                        implicitWidthBehavior.enabled = true;
                    }

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: implicitWidth > parent.width ? -(implicitWidth - parent.width) / 2 : 0
                    implicitWidth: fullWidth
                    implicitHeight: dotSize
                    orientation: ListView.Horizontal
                    spacing: Math.round(Sizes.lockCardGap / 2)
                    interactive: false
                    model: dotsModel

                    Behavior on implicitWidth {
                        id: implicitWidthBehavior

                        NumberAnimation {
                            duration: Appearance.animation.standard.duration
                            easing.type: Appearance.animation.standard.type
                            easing.bezierCurve: Appearance.animation.standard.bezierCurve
                        }
                    }

                    delegate: Rectangle {
                        id: dot

                        width: dotsList.dotSize
                        height: dotsList.dotSize
                        radius: Sizes.lockCardRadiusSmall / 2
                        color: Appearance.colors.colOnSurface
                        opacity: 0
                        scale: 0

                        Component.onCompleted: {
                            opacity = 1;
                            scale = 1;
                        }

                        ListView.onRemove: removeAnim.start()

                        SequentialAnimation {
                            id: removeAnim

                            PropertyAction {
                                target: dot
                                property: "ListView.delayRemove"
                                value: true
                            }

                            ParallelAnimation {
                                NumberAnimation {
                                    target: dot
                                    property: "opacity"
                                    to: 0
                                    duration: Appearance.animation.expressiveEffects.duration
                                    easing.type: Appearance.animation.expressiveEffects.type
                                    easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                                }
                                NumberAnimation {
                                    target: dot
                                    property: "scale"
                                    to: 0.5
                                    duration: Appearance.animation.expressiveFastSpatial.duration
                                    easing.type: Appearance.animation.expressiveFastSpatial.type
                                    easing.bezierCurve: Appearance.animation.expressiveFastSpatial.bezierCurve
                                }
                            }

                            PropertyAction {
                                target: dot
                                property: "ListView.delayRemove"
                                value: false
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Appearance.animation.expressiveEffects.duration
                                easing.type: Appearance.animation.expressiveEffects.type
                                easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: Appearance.animation.expressiveFastSpatial.duration
                                easing.type: Appearance.animation.expressiveFastSpatial.type
                                easing.bezierCurve: Appearance.animation.expressiveFastSpatial.bezierCurve
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: enterButton

                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth + (enterMouse.pressed ? Sizes.lockOuterPadding * 2 : root.hasText ? Sizes.lockOuterPadding : 0)
                implicitWidth: enterIcon.implicitWidth + Sizes.lockOuterPadding * 2
                implicitHeight: enterIcon.implicitHeight + Math.round(10 * 4 / 3) * 2
                radius: root.hasText || enterMouse.pressed ? Math.round(17 * 4 / 3) : Math.min(implicitWidth, implicitHeight) / 2
                color: root.hasText ? Appearance.colors.colPrimary : Appearance.colors.colLayer3

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: Appearance.animation.expressiveFastSpatial.duration
                        easing.type: Appearance.animation.expressiveFastSpatial.type
                        easing.bezierCurve: Appearance.animation.expressiveFastSpatial.bezierCurve
                    }
                }

                Behavior on radius {
                    NumberAnimation {
                        duration: Appearance.animation.expressiveFastSpatial.duration
                        easing.type: Appearance.animation.expressiveFastSpatial.type
                        easing.bezierCurve: Appearance.animation.expressiveFastSpatial.bezierCurve
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.standard.duration
                        easing.type: Appearance.animation.standard.type
                        easing.bezierCurve: Appearance.animation.standard.bezierCurve
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: root.hasText ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                    opacity: enterMouse.pressed ? 0.2 : enterMouse.containsMouse ? 0.12 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.animation.expressiveEffects.duration
                            easing.type: Appearance.animation.expressiveEffects.type
                            easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                        }
                    }
                }

                Text {
                    id: enterIcon

                    anchors.centerIn: parent
                    text: "arrow_forward"
                    color: root.hasText ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 24
                    font.weight: 500
                }

                MouseArea {
                    id: enterMouse

                    anchors.fill: parent
                    enabled: root.hasText && !root.busy
                    hoverEnabled: enabled
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        input.forceActiveFocus();
                        root.requestUnlock();
                    }
                }
            }
        }

        HoverHandler {
            id: frameHover

            cursorShape: Qt.IBeamCursor
        }

        TapHandler {
            id: frameTap

            acceptedButtons: Qt.LeftButton
            onTapped: eventPoint => {
                if (eventPoint.position.x < enterButton.x)
                    ripple.start(eventPoint.position.x, eventPoint.position.y);

                input.forceActiveFocus();
            }
        }
    }
}
