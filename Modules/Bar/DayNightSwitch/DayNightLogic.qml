import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // 对外暴露的状态：当前是否为深色模式
    property bool isDark: false

    // --- 1. 初始化检查 ---
    Process {
        command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
        running: true // 组件加载时运行一次
        stdout: SplitParser {
            onRead: data => {
                if (data.includes('prefer-dark')) root.isDark = true
                else root.isDark = false
            }
        }
    }

    // --- 2. 持续监听 ---
    Process {
        // monitor 命令会挂起并实时输出变更
        command: ["gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.includes('prefer-dark')) {
                    root.isDark = true
                } else if (data.includes('default') || data.includes('prefer-light')) {
                    root.isDark = false
                }
            }
        }
    }

    // --- 3. 对外暴露的方法：切换主题 ---
    function toggle() {
        var newScheme = root.isDark ? 'default' : 'prefer-dark'
        Quickshell.execDetached([
            "gsettings", "set", "org.gnome.desktop.interface", "color-scheme", newScheme
        ])
        // 注意：这里不需要手动设置 root.isDark
        // 因为 execDetached 执行后，系统状态改变，monitor 进程会监听到并自动更新 isDark
    }
}
