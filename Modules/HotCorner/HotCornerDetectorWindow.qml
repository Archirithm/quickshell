// Modules/HotCorner/HotCornerDetectorWindow.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: root
    
    WlrLayershell.layer: WlrLayer.Top 
    WlrLayershell.namespace: "qs-hotcorner-bottom-right"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors { right: true; bottom: true }
    
    // 【修改】：10x10 像素，隐形且更容易触发
    implicitWidth: 10
    implicitHeight: 10
    color: "transparent"

    // ============================================================
    // 【新增】：防误触 1 秒延迟逻辑
    // ============================================================
    Timer {
        id: openTimer
        interval: 1000 // 悬浮 1 秒钟打开
        onTriggered: WidgetState.notifOpen = true
    }

    Timer {
        id: closeTimer
        interval: 1000 // 移开 1 秒钟关闭
        onTriggered: {
            // 如果鼠标此时没有移动到通知面板上，才真正关闭
            if (!WidgetState.notifIsHovered) {
                WidgetState.notifOpen = false;
            }
        }
    }

    MouseArea {
        id: hotCornerDetector
        anchors.fill: parent
        hoverEnabled: true 
        
        onEntered: {
            closeTimer.stop();
            openTimer.start();
        }
        onExited: {
            openTimer.stop();
            closeTimer.start();
        }
    }
}
