import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.config

Rectangle {
    id: root

    property string buttonText: ""
    property string iconName: ""
    property string urgency: NotificationUrgency.Normal.toString()
    property bool hovered: mouseArea.containsMouse
    property bool pressed: mouseArea.pressed
    property color rippleColor: root.urgency === NotificationUrgency.Critical.toString()
        ? Appearance.colors.colSecondaryContainerActive
        : Appearance.colors.colLayer4Active

    signal clicked()

    implicitHeight: 34
    implicitWidth: Math.max(64, contentRow.implicitWidth + 30)
    radius: Appearance.rounding.small
    color: root.urgency === NotificationUrgency.Critical.toString()
        ? (pressed ? Appearance.colors.colSecondaryContainerActive : hovered ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer)
        : (pressed ? Appearance.colors.colLayer4Active : hovered ? Appearance.colors.colLayer4Hover : Appearance.colors.colLayer4)
    scale: pressed ? 0.98 : hovered ? 1.01 : 1
    clip: true

    function startRipple(x, y) {
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
        spacing: 6

        Text {
            visible: root.iconName !== ""
            text: root.iconName
            font.family: "Material Symbols Rounded"
            font.pixelSize: 20
            color: root.urgency === NotificationUrgency.Critical.toString()
                ? Appearance.colors.colOnSecondaryContainer
                : Appearance.colors.colOnLayer4
        }

        Text {
            visible: root.buttonText !== ""
            text: root.buttonText
            font.family: Sizes.fontFamily
            font.pixelSize: 12
            font.bold: true
            color: root.urgency === NotificationUrgency.Critical.toString()
                ? Appearance.colors.colOnSecondaryContainer
                : Appearance.colors.colOnLayer4
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                root.startRipple(mouse.x, mouse.y);
        }
        onClicked: root.clicked()
    }
}
