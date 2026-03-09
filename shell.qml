//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Io  
import QtQuick        
import qs.Modules.Bar
import qs.Modules.Launcher 

// 【新增】引入独立出来的灵动岛
import qs.Modules.DynamicIsland

ShellRoot {
    // 你的状态栏
    Bar {}
    
    // 【新增】实例化独立的灵动岛窗口
    DynamicIsland {}

    // ================= 锁屏管理器 =================
    Loader {
        id: lockLoader
        active: false 
        
        source: "Modules/Lock/Lock.qml"
        
        Connections {
            target: lockLoader.item 
            ignoreUnknownSignals: true
            
            function onUnlocked() {
                lockLoader.active = false
            }
        }
    }

    IpcHandler {
        target: "lock" 
        
        function open() {
            if (!lockLoader.active) {
                lockLoader.active = true
                return "LOCKED"
            }
            return "ALREADY_LOCKED"
        }
    }

    // ================= 启动器 (Launcher) =================
    
    LauncherWindow {
        id: rofiLauncher
    }

    IpcHandler {
        target: "launcher"
        
        function toggle() {
            rofiLauncher.toggleWindow(); 
            return "LAUNCHER_TOGGLED";
        }
    }
}
