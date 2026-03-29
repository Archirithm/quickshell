// shell.qml
//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Io  
import QtQuick        
import qs.Modules.Bar
import qs.Modules.Launcher 
import qs.Modules.DynamicIsland
// 【新增】：引入你重构后的 Widget 文件夹
import qs.Widget
// 【新增】：引入热角触发器路径
import "./Modules/HotCorner"

ShellRoot {
    Bar {}
    
    DynamicIsland {}

    // 【新增】：实例化全局“热角” IPC 信号控制器，用于设置菜单全局控制
    IpcHandler {
        target: "hotcorner"
        
        // 信号：启用或禁用所有热角
        function setEnabled(code) {
            WidgetState.hotCornerEnabled = code
            return `HotCorner set to: ${code}`
        }
        
        // 信号：切换热角状态
        function toggle() {
            WidgetState.hotCornerEnabled = !WidgetState.hotCornerEnabled
            return `HotCorner toggled to: ${WidgetState.hotCornerEnabled}`
        }
    }

    // 【删除】：之前的独立 Widget（AudioWidget, NetworkWidget, NotificationWidget）
    // AudioWidget {}
    // NetworkWidget {}
    // NotificationWidget {}

    // 【新增】：挂载快捷设置侧边栏 (上半部，无消息面板)
    // 只要放在 ShellRoot 里，它自己配置的 Wayland Overlay 属性就会让它完美悬浮在右上侧
    RightSidebar {}

    // ============================================================
    // 【新增】：挂载独立的消息面板与热角检测器
    // ============================================================
    // 1. 无形的“热角”检测器，固定在屏幕最右下角。
    HotCornerDetectorWindow {}
    
    // 2. 独立的“内凹曲线果冻消息面板”，固定在屏幕右下角。
    NotificationCornerWindow {}

    // ================= 锁屏管理器 =================
    // (保持不变)
    Loader { id: lockLoader; active: false; source: "Modules/Lock/Lock.qml"
        Connections { target: lockLoader.item; ignoreUnknownSignals: true; function onUnlocked() { lockLoader.active = false } }
    }
    IpcHandler { target: "lock"; function open() { if (!lockLoader.active) { lockLoader.active = true; return "LOCKED" } return "ALREADY_LOCKED" } }

    // ================= 启动器 (Launcher) =================
    // (保持不变)
    LauncherWindow { id: rofiLauncher }
    IpcHandler { target: "launcher"; function toggle() { rofiLauncher.toggleWindow(); return "LAUNCHER_TOGGLED"; } }
}
