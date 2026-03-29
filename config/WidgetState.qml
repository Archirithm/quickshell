// config/WidgetState.qml
pragma Singleton
import QtQuick
// 【新增】：引入 Quickshell 的 IPC 机制
import Quickshell.Io 

QtObject {
    // 快捷设置面板（音量/网络）开关状态
    property bool qsOpen: false
    // 快捷设置面板内部视图："network" 或 "audio"
    property string qsView: "network" 
    
    // 【核心修改】：通知中心面板开关状态
    property bool notifOpen: false
    
    // ============================================================
    // 【新增】：全局“热角”配置与 IPC 处理
    // ============================================================
    // 全局热角功能的开关 (默认开启)
    property bool hotCornerEnabled: true
    
    // 处理热角触发请求
    function openNotifPanelFromHotCorner() {
        if (hotCornerEnabled && !notifOpen) {
            notifOpen = true;
        }
    }
}
