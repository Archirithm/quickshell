// Modules/HotCorner/HotCornerDetectorWindow.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: root
    
    // 【致命 Bug 修复】：降级为 Top，全屏看视频时自动隐藏！
    WlrLayershell.layer: WlrLayer.Top 
    WlrLayershell.namespace: "qs-hotcorner-bottom-right"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    
    // 【核心修复】：声明此窗口不抢占任何屏幕物理空间！
    exclusiveZone: 0

    anchors { right: true; bottom: true }
    
    // 真正的 1x1 像素幽灵侦测器
    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"

    MouseArea {
        id: hotCornerDetector
        anchors.fill: parent
        hoverEnabled: true 
        
        onEntered: {
            WidgetState.openNotifPanelFromHotCorner();
        }
    }
}
