//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Io  
import QtQuick        
import qs.Modules.Bar

// 【新增】引入你的启动器模块（路径取决于你 qmldir 的配置，如果是按之前的路径，可以直接这样引入）
import qs.Modules.Launcher 

ShellRoot {
    // 你的状态栏保持不变
    Bar {}

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
    
    // 【新增】实例化启动器窗口，默认隐藏 (预加载模式，保证零延迟弹出)
    LauncherWindow {
        id: rofiLauncher
    }

    IpcHandler {
        target: "launcher"
        
        function toggle() {
            // 【关键】：这里一定要调用我们自定义的优雅开关接口！
            rofiLauncher.toggleWindow(); 
            return "LAUNCHER_TOGGLED";
        }
    }
}
