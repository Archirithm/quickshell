import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes 
import Quickshell
import qs.Services
import qs.config
import qs.Widget

Item {
    id: root

    property bool isHovered: mouseArea.containsMouse

    implicitHeight: 28
    // 平时只显示 28x28 的仪表盘，悬停时撑开容纳文字宽度
    implicitWidth: isHovered ? (layout.width) : 28

    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    AudioWidget { id: audioPanel; isOpen: false }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6

        // 1. 仪表盘与中心图标
        Item {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28

            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.samples: 4 

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Colorscheme.surface_variant
                    strokeWidth: 3 
                    capStyle: ShapePath.RoundCap 
                    PathAngleArc {
                        centerX: 14; centerY: 14
                        radiusX: 12; radiusY: 12
                        startAngle: 135
                        sweepAngle: 270
                    }
                }

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: (Volume.sinkMuted || Volume.sinkVolume <= 0) ? Colorscheme.error : Colorscheme.primary
                    strokeWidth: 3
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: 14; centerY: 14
                        radiusX: 12; radiusY: 12
                        startAngle: 135
                        sweepAngle: 270 * Volume.sinkVolume
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                font.pixelSize: 10
                color: (Volume.sinkMuted || Volume.sinkVolume <= 0) ? Colorscheme.error : Colorscheme.on_surface
                text: {
                    if (Volume.isHeadphone) return ""
                    if (Volume.sinkMuted || Volume.sinkVolume <= 0) return ""
                    if (Volume.sinkVolume < 0.5) return ""
                    return ""
                }
            }
        }

        // 2. 悬浮时展示的百分比文字
        Text {
            id: volText
            text: Math.round(Volume.sinkVolume * 100) + "%"
            
            // 使用你指定的 JetBrains Mono Nerd Font
            font.family: "JetBrainsMono Nerd Font" 
            font.bold: true
            font.pixelSize: 12
            color: Colorscheme.on_surface
            Layout.alignment: Qt.AlignVCenter

            // 悬停动画逻辑
            visible: root.isHovered
            opacity: root.isHovered ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onWheel: (wheel) => {
            const step = 0.05
            let newVol = Volume.sinkVolume
            if (wheel.angleDelta.y > 0) newVol += step
            else newVol -= step
            Volume.setSinkVolume(newVol)
        }
        onClicked: audioPanel.isOpen = !audioPanel.isOpen
    }
}
