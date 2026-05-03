import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects  // 引入 Qt 6 特效库
import qs.config

Item {
    id: root
    
    // 高度与 Workspaces 统一为 36
    implicitHeight: 36
    // 宽度 = 图标总宽 + 左右各 12px 的留白 (共 24px)
    implicitWidth: content.width + 24

    // 1. 定义原背景（设为不可见，仅作为渲染源）
    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: Appearance.colors.colLayer0
        radius: height / 2 // 完美的药丸圆角
        visible: false 
    }

    // 2. 使用 MultiEffect 渲染药丸背景 + 外部阴影
    MultiEffect {
        source: bgRect
        anchors.fill: bgRect
        shadowEnabled: true
        shadowColor: Qt.alpha(Appearance.colors.colShadow, 0.4) 
        shadowBlur: 0.8
        shadowVerticalOffset: 3
        shadowHorizontalOffset: 0
    }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 10 // 稍微加大一点图标间距，让呼吸感更强

        Repeater {
            model: SystemTray.items
            
            delegate: TrayItem {
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
