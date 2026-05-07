import QtQuick
import QtQuick.Layouts
import qs.Common

Rectangle {
    id: root

    property string buttonIcon: ""
    property string buttonText: ""
    property bool toggled: false
    property bool hovered: mouseArea.containsMouse
    property bool pressed: mouseArea.pressed
    property color rippleColor: toggled ? Appearance.colors.colPrimaryActive : Appearance.colors.colLayer2Active

    signal clicked()

    implicitHeight: 36
    implicitWidth: Math.max(contentRow.implicitWidth + 34, 46)
    radius: height / 2
    color: toggled
        ? (pressed ? Appearance.colors.colPrimaryActive : hovered ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary)
        : (pressed ? Appearance.colors.colLayer2Active : hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)
    scale: pressed ? 0.96 : hovered ? 1.01 : 1
    transformOrigin: Item.Center
    clip: true

    function startRipple(x, y) {
        if (!root.enabled)
            return;
        ripple.centerX = x;
        ripple.centerY = y;
        rippleAnimation.diameter = Math.sqrt(root.width * root.width + root.height * root.height) * 2.2;
        rippleAnimation.restart();
    }

    Behavior on color {
        ColorAnimation {
            duration: Appearance.animation.expressiveEffects.duration
            easing.type: Appearance.animation.expressiveEffects.type
            easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: Appearance.animation.clickBounce.duration
            easing.type: Appearance.animation.clickBounce.type
            easing.bezierCurve: Appearance.animation.clickBounce.bezierCurve
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
            from: 0.22
            to: 0
            duration: 1200
            easing.type: Appearance.animation.standardDecel.type
            easing.bezierCurve: Appearance.animation.standardDecel.bezierCurve
        }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            visible: root.buttonIcon !== ""
            text: root.buttonIcon
            font.family: "Material Symbols Rounded"
            font.pixelSize: 20
            color: root.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        }

        Text {
            visible: root.buttonText !== ""
            text: root.buttonText
            font.family: Sizes.fontFamily
            font.pixelSize: 12
            font.bold: true
            color: root.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: root.enabled
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                root.startRipple(mouse.x, mouse.y);
        }
        onClicked: root.clicked()
    }
}
