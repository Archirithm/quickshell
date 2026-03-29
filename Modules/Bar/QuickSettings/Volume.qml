import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes 
import Quickshell
import qs.Services
import qs.config

Item {
    id: root
    implicitHeight: 28
    implicitWidth: 28

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
                startAngle: 135; sweepAngle: 270
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

    MouseArea {
        anchors.fill: parent
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
