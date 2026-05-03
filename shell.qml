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
import "./Widget/left_sidebar"

ShellRoot {
    Bar {}
    
    DynamicIsland {}

    LeftSidebarWindow {}
    // 【新增】：挂载快捷设置侧边栏 (上半部，无消息面板)
    // 只要放在 ShellRoot 里，它自己配置的 Wayland Overlay 属性就会让它完美悬浮在右上侧
    RightSidebar {}

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
