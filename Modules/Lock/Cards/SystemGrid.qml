import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Clavis.Sysmon 1.0
import qs.Common

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 280
    
    color: Appearance.colors.colLayer2
    radius: Sizes.lockCardRadius

    // ================== 网格布局 ==================
    GridLayout {
        anchors.fill: parent
        anchors.margins: Sizes.lockCardPadding
        columns: 2
        rowSpacing: 15
        columnSpacing: 15

        // 1. CPU (紫色)
        SystemCircle { 
            title: "CPU"
            icon: "memory"
            value: SysmonPlugin.cpuUsage / 100.0
            display: Math.round(SysmonPlugin.cpuUsage) + "%"
            accent: Appearance.colors.colPrimary
        }

        // 2. Temp (红/橙色)
        SystemCircle { 
            title: "TEMP"
            icon: "thermostat"
            value: Math.min(Math.max(SysmonPlugin.coreTemp / 100.0, 0), 1)
            display: Math.round(SysmonPlugin.coreTemp) + "°C"
            accent: Appearance.colors.colError
        }

        // 3. RAM (蓝色)
        SystemCircle { 
            title: "RAM"
            icon: "developer_board"
            value: SysmonPlugin.ramUsage / 100.0
            display: SysmonPlugin.ramUsedGB.toFixed(1) + "G"
            accent: Appearance.colors.colSecondary
        }

        // 4. Disk (青/黄色)
        SystemCircle { 
            title: "DISK"
            icon: "hard_disk"
            value: SysmonPlugin.diskUsage / 100.0
            display: Math.round(SysmonPlugin.diskUsage) + "%"
            accent: Appearance.colors.colTertiary
        }
    }

    // ================== 圆形组件封装 ==================
    component SystemCircle: Item {
        property string title
        property string icon
        property real value: 0.0
        property string display: ""
        property color accent
        property real animatedValue: value
        
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        // 每个格子的背景
        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colLayer4
            radius: 16
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            // 进度环容器
            Item {
                width: 60; height: 60
                Layout.alignment: Qt.AlignHCenter
                
                // 旋转 -90 度，让进度从顶部开始
                Shape {
                    anchors.centerIn: parent
                    width: parent.width; height: parent.height
                    rotation: -90
                    
                    // 1. 底部轨道 (暗色)
                    ShapePath {
                        strokeColor: Qt.rgba(Appearance.colors.colOnSurface.r, Appearance.colors.colOnSurface.g, Appearance.colors.colOnSurface.b, 0.1)
                        strokeWidth: 6
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc { centerX: 30; centerY: 30; radiusX: 27; radiusY: 27; startAngle: 0; sweepAngle: 360 }
                    }
                    
                    // 2. 进度条 (亮色)
                    ShapePath {
                        strokeColor: accent
                        strokeWidth: 6
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc { 
                            centerX: 30; centerY: 30; radiusX: 27; radiusY: 27; 
                            startAngle: 0; 
                            sweepAngle: 360 * (Math.min(Math.max(animatedValue, 0), 1))
                        }
                    }
                }
                
                // 中间的图标
                Text {
                    anchors.centerIn: parent
                    text: icon
                    color: accent
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 22
                }
            }
            
            // 底部文字 (标题 + 数值)
            Text {
                text: display
                color: Appearance.colors.colOnSurface
                font.family: Sizes.fontFamilyMono
                font.pixelSize: 12
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Behavior on animatedValue {
            NumberAnimation {
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
            }
        }
    }
}
