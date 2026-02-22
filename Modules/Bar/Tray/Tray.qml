import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root
    
    // --- 样式：与其他模块完全统一 ---
    color: Colorscheme.background
    radius: Sizes.cornerRadius
    
    // 高度固定为 40
    implicitHeight: Sizes.barHeight
    
    // 宽度 = 图标总宽 + 左右各 12px 的留白 (共 24px)
    // 这样当没有托盘图标时，宽度会自动收缩，有图标时自动撑开
    implicitWidth: content.width + 24

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 8 // 图标之间的间距

        Repeater {
            model: SystemTray.items
            
            delegate: TrayItem {
                // 确保图标在 40px 高度的条里垂直居中
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
