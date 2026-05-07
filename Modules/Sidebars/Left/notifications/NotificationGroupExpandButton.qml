import QtQuick
import QtQuick.Layouts
import qs.Common

Rectangle {
    id: root

    required property int count
    required property bool expanded
    property bool hovered: mouseArea.containsMouse
    property bool pressed: mouseArea.pressed
    property color rippleColor: Appearance.colors.colLayer2Active
    property real fontSize: 12

    signal clicked()

    implicitHeight: fontSize + 10
    implicitWidth: Math.max(contentRow.implicitWidth + 12, 32)
    radius: height / 2
    color: pressed
        ? Appearance.colors.colLayer2Active
        : hovered ? Appearance.colors.colLayer2Hover : Appearance.mix(Appearance.colors.colLayer2, Appearance.colors.colLayer2Hover, 0.5)
    clip: true

    function startRipple(x, y) {
        ripple.centerX = x;
        ripple.centerY = y;
        rippleAnimation.diameter = Math.sqrt(root.width * root.width + root.height * root.height) * 2.4;
        rippleAnimation.restart();
    }

    Behavior on color {
        ColorAnimation {
            duration: Appearance.animation.expressiveEffects.duration
            easing.type: Appearance.animation.expressiveEffects.type
            easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
        }
    }

    Rectangle {
        id: ripple
        property real centerX: root.width / 2
        property real centerY: root.height / 2
        property real diameter: 0

        x: centerX - width / 2
        y: centerY - height / 2
        width: diameter
        height: diameter
        radius: width / 2
        color: root.rippleColor
        opacity: 0
        visible: opacity > 0
    }

    ParallelAnimation {
        id: rippleAnimation
        property real diameter: 0

        NumberAnimation {
            target: ripple
            property: "diameter"
            from: 0
            to: rippleAnimation.diameter
            duration: 1200
            easing.type: Appearance.animation.standardDecel.type
            easing.bezierCurve: Appearance.animation.standardDecel.bezierCurve
        }
        NumberAnimation {
            target: ripple
            property: "opacity"
            from: 0.28
            to: 0
            duration: 1200
            easing.type: Appearance.animation.standardDecel.type
            easing.bezierCurve: Appearance.animation.standardDecel.bezierCurve
        }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 2

        Text {
            visible: root.count > 1
            text: root.count
            font.family: Sizes.fontFamilyMono
            font.pixelSize: root.fontSize
            font.bold: true
            color: Appearance.colors.colOnLayer2
        }

        Text {
            text: "keyboard_arrow_down"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 18
            rotation: root.expanded ? 180 : 0
            color: Appearance.colors.colOnLayer2

            Behavior on rotation {
                NumberAnimation {
                    duration: Appearance.animation.expressiveEffects.duration
                    easing.type: Appearance.animation.expressiveEffects.type
                    easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                root.startRipple(mouse.x, mouse.y);
        }
        onClicked: root.clicked()
    }
}
