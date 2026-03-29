import QtQuick
import QtQuick.Layouts
import qs.config
import qs.Widget.common

Item {
    id: root

    Item {
        id: sliderTrack
        width: root.width * 2
        height: root.height
        
        x: WidgetState.qsView === "audio" ? -root.width : 0
        
        // 【核心修复】：加上 enabled 判断！
        // 只有当面板处于打开状态时，才允许播放平滑的切换动画。
        // 面板关闭时，动画失效，轨道会在 0 毫秒内瞬间完成位置切换。
        Behavior on x { 
            enabled: WidgetState.qsOpen
            NumberAnimation { duration: 360; easing.type: Easing.OutQuint } 
        }

        Row {
            anchors.fill: parent
            
            Item {
                width: root.width
                height: root.height
                NetworkContent { anchors.fill: parent }
            }

            Item {
                width: root.width
                height: root.height
                AudioContent { anchors.fill: parent }
            }
        }
    }
}
