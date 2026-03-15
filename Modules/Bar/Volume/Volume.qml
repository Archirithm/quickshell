import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes // 引入绘图组件
import Quickshell
import qs.Services
import qs.config
import qs.Widget

Item {
    id: root

    implicitHeight: 28
    implicitWidth: 28

    AudioWidget { id: audioPanel; isOpen: false }

    // 绘制仪表盘
    Shape {
        anchors.fill: parent
        // 开启抗锯齿，保证圆弧平滑
        layer.enabled: true
        layer.samples: 4 

        // 1. 底部轨道 (灰色)
        ShapePath {
            fillColor: "transparent"
            strokeColor: Colorscheme.surface_variant
            strokeWidth: 3 // 圆环粗细
            capStyle: ShapePath.RoundCap // 圆角端点
            
            PathAngleArc {
                centerX: 14; centerY: 14
                radiusX: 12; radiusY: 12
                // 从左下角 135 度开始，跨越 270 度到右下角
                startAngle: 135
                sweepAngle: 270
            }
        }

        // 2. 进度条 (高亮色)
        ShapePath {
            fillColor: "transparent"
            // 静音时变红，否则为主题主色
            strokeColor: (Volume.sinkMuted || Volume.sinkVolume <= 0) ? Colorscheme.error : Colorscheme.primary
            strokeWidth: 3
            capStyle: ShapePath.RoundCap
            
            PathAngleArc {
                centerX: 14; centerY: 14
                radiusX: 12; radiusY: 12
                startAngle: 135
                // 根据音量比例动态计算弧度
                sweepAngle: 270 * Volume.sinkVolume
            }
        }
    }

    // 中心图标
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
        onClicked: audioPanel.isOpen = !audioPanel.isOpen
    }
}
