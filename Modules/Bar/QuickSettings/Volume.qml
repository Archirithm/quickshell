import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes 
import Quickshell
import qs.Services
import qs.config

Item {
    id: root
    property bool isHovered: mouseArea.containsMouse

    // 默认高度 28，宽度在悬浮时平滑展开以容纳数字
    implicitHeight: 28
    implicitWidth: isHovered ? layout.implicitWidth : 28

    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        // 图标和表盘部分
        Item {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28

            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.samples: 4 

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Appearance.colors.colLayer2Hover
                    strokeWidth: 3
                    capStyle: ShapePath.RoundCap 
                    PathAngleArc {
                        centerX: 14; centerY: 14
                        radiusX: 12; radiusY: 12
                        startAngle: 135; sweepAngle: 270
                    }
                }

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: (Volume.sinkMuted || Volume.sinkVolume <= 0) ? Appearance.colors.colError : Appearance.colors.colPrimary
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
                color: (Volume.sinkMuted || Volume.sinkVolume <= 0) ? Appearance.colors.colError : Appearance.colors.colOnSurface
                text: {
                    if (Volume.isHeadphone) return ""
                    if (Volume.sinkMuted || Volume.sinkVolume <= 0) return ""
                    if (Volume.sinkVolume < 0.5) return ""
                    return ""
                }
            }
        }

        // 音量数字部分（无百分号，指定字体）
        Text {
            id: volText
            text: Math.round(Volume.sinkVolume * 100).toString()
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: true
            color: Appearance.colors.colOnSurface
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
        onClicked: {
            if (WidgetState.qsOpen && WidgetState.qsView === "audio") {
                WidgetState.qsOpen = false;
            } else {
                WidgetState.qsView = "audio";
                WidgetState.qsOpen = true;
            }
        }
    }
}
