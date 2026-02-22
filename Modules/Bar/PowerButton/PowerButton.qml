import QtQuick
import Quickshell
import qs.config

Rectangle {
    id: root

    // --- 样式设定 ---
    color: Colorscheme.error 
    
    // 圆角和高度保持和其他胶囊一致
    radius: Sizes.cornerRadius
    implicitHeight: Sizes.barHeight
    
    // 宽度自适应，左右各留 12px 边距 (24px)
    // 这样如果只有图标，它会是一个近似正方形的圆角按钮
    implicitWidth: icon.contentWidth + 20

    // --- 交互区域 ---
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        
        // 左键点击运行 wlogout 命令
        onClicked: {
            Quickshell.execDetached(["wlogout", "-p", "layer-shell", "-b", "2"])
        }
    }

    // --- 图标内容 ---
    Text {
        id: icon
        anchors.centerIn: parent
        
        text: "⏻"
        font.pixelSize: 15 //稍微大一点，突出电源键
        font.bold: true
        
        color: Colorscheme.background 
    }
}
