import QtQuick
import qs.Common

Item {
    id: root

    // === 必需属性 ===
    required property bool isPlaying

    // === 颜色属性 ===
    property color playingBg: Appearance.colors.colPrimary
    property color playingFg: Appearance.colors.colOnPrimary
    property color pausedBg: Appearance.colors.colSecondaryContainer
    property color pausedFg: Appearance.colors.colOnSecondaryContainer
    property color stateLayerPlaying: Appearance.colors.colOnPrimary
    property color stateLayerPaused: Appearance.colors.colOnSecondaryContainer

    // === 尺寸属性 ===
    property real buttonSize: 54
    property real iconSize: 34
    property string iconFontFamily: "Material Symbols Outlined"
    property string playIconName: "play_arrow"
    property string pauseIconName: "pause"

    // === 形变动画 ===
    property bool morphEnabled: true       // 是否启用宽度/圆角形变
    property real morphExpandWidth: 10     // 播放时额外宽度
    property real morphPressWidth: 18      // 按下时额外宽度
    property real morphPlayingRadius: 16   // 播放时圆角
    property real morphPressRadius: 12     // 按下时圆角
    property real pressedScale: 1.0
    property real hoverScale: 1.0
    property int scaleAnimationDuration: 150
    property real stateLayerPressedOpacity: 0.2
    property real stateLayerHoverOpacity: 0.12
    property int spatialAnimationDuration: 350
    property int colorAnimationDuration: 400
    property int stateLayerAnimationDuration: 200
    property int iconSwapHalfDuration: 200
    property var spatialCurve: [0.42, 1.67, 0.21, 0.9, 1, 1]
    property var colorCurve: [0.2, 0, 0, 1, 1, 1]
    property var iconOutCurve: [0.3, 0, 1, 1, 1, 1]
    property var iconInCurve: [0, 0, 0, 1, 1, 1]

    // === 信号 ===
    signal clicked()

    implicitWidth: morphEnabled ? (buttonSize + morphExpandWidth + morphPressWidth) : buttonSize
    implicitHeight: buttonSize
    scale: playMa.pressed ? pressedScale : (playMa.containsMouse ? hoverScale : 1.0)

    Behavior on scale { NumberAnimation { duration: root.scaleAnimationDuration } }

    Rectangle {
        id: btnRect
        anchors.centerIn: parent

        width: {
            if (!root.morphEnabled) return root.buttonSize;
            return root.buttonSize + (playMa.pressed ? root.morphPressWidth
                : (root.isPlaying ? root.morphExpandWidth : 0));
        }
        height: root.buttonSize

        radius: {
            if (!root.morphEnabled) return root.buttonSize / 2;
            return playMa.pressed ? root.morphPressRadius
                : (root.isPlaying ? root.morphPlayingRadius : root.buttonSize / 2);
        }

        color: root.isPlaying ? root.playingBg : root.pausedBg

        Behavior on width {
            NumberAnimation {
                duration: root.spatialAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.spatialCurve
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: root.spatialAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.spatialCurve
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: root.colorAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.colorCurve
            }
        }

        // StateLayer 涟漪层
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.isPlaying ? root.stateLayerPlaying : root.stateLayerPaused
            opacity: playMa.pressed ? root.stateLayerPressedOpacity : (playMa.containsMouse ? root.stateLayerHoverOpacity : 0.0)
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: root.stateLayerAnimationDuration } }
        }

        // 播放/暂停图标
        Text {
            id: playIcon
            anchors.centerIn: parent
            text: root.isPlaying ? root.pauseIconName : root.playIconName
            color: root.isPlaying ? root.playingFg : root.pausedFg
            font.family: root.iconFontFamily
            font.pixelSize: root.iconSize

            Behavior on color {
                ColorAnimation {
                    duration: root.colorAnimationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.colorCurve
                }
            }

            // 图标切换动画：缩小→换文字→放大
            Behavior on text {
                SequentialAnimation {
                    NumberAnimation {
                        target: playIcon; property: "scale"
                        to: 0.0; duration: root.iconSwapHalfDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.iconOutCurve
                    }
                    PropertyAction { target: playIcon; property: "text" }
                    NumberAnimation {
                        target: playIcon; property: "scale"
                        to: 1.0; duration: root.iconSwapHalfDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.iconInCurve
                    }
                }
            }
        }

        MouseArea {
            id: playMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
