import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Services
import qs.config

// 【1】 导入你的组件路径
// 如果 NetworkWidget.qml 在上一级的 Widget 文件夹里：
import qs.Widget 
// 或者如果它就在旁边，直接用 import "." 即可

Rectangle {
    id: root
    
    // --- 胶囊样式 ---
    color: Colorscheme.background
    radius: Sizes.cornerRadius
    implicitHeight: Sizes.barHeight
    implicitWidth: layout.width + 24

    // --- 【2】 实例化网络面板 ---
    NetworkWidget {
        id: wifiPanel
        // 默认是关闭的
        isOpen: false
        
        // 如果你想让面板的配色跟随全局 Colorscheme，可以在这里覆盖内部属性
        // (前提是 NetworkWidget 内部没有把这些属性写死，而是开放了别名或者属性)
        // 目前你的 NetworkWidget 是自包含配色的，直接用即可。
    }

    // --- 交互区域 ---
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        
        // --- 【3】 修改点击逻辑 ---
        onClicked: {
            // 切换面板的开关状态
            wifiPanel.isOpen = !wifiPanel.isOpen
        }
    }

    // --- 内容布局 (保持不变) ---
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        Text {
            font.family: "Font Awesome 6 Free Regular" 
            font.pixelSize: 16
            
            // 颜色：连上是青色，断开是红色
            color: Network.connected ? Colorscheme.on_tertiary_container : "#ff5555"
            
            text: {
                if (Network.activeConnectionType === "WIFI") return ""
                if (Network.activeConnectionType === "ETHERNET") return ""
                return "⚠"
            }
        }

        Text {
            font.bold: true
            font.pixelSize: 14
            color: Colorscheme.on_primary_container
            // 直接读取 Service 数据
            text: Network.activeConnection
        }
    }
}
