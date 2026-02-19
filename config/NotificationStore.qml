pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

QtObject {
    id: root

    // ================= 1. 核心数据模型 =================
    readonly property ListModel model: ListModel {}

    // ================= 2. 配置项 =================
    property int maxCount: 20
    property var privacyApps: ["qq", "wechat", "telegram", "discord"]
    
    // 脚本路径
    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/notify_db.py"

    // ================= 3. 持久化逻辑 (Load/Save) =================
    
    // 启动时加载数据
    Component.onCompleted: {
        loadProcess.running = true
    }

    // 加载进程
    property var loadProcess: Process {
        command: ["python3", root.scriptPath, "load"]
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    var loaded = JSON.parse(data.trim());
                    root.model.clear();
                    // 倒序插入，保持时间顺序
                    for (var i = 0; i < loaded.length; i++) {
                        root.model.append(loaded[i]);
                    }
                } catch(e) {
                    console.log("Failed to load notifications:", e);
                }
            }
        }
    }

    // 保存进程
    property var saveProcess: Process {
        // 动态设置参数
        command: ["python3", root.scriptPath, "save", "[]"] 
    }

    // 触发保存（带防抖）
    function requestSave() {
        saveTimer.restart();
    }

    // 防抖定时器：数据变化 1秒后 再写入磁盘，避免频繁 IO
    property var saveTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: {
            // 1. 将 Model 序列化为 JSON 字符串
            var data = [];
            for (var i = 0; i < root.model.count; i++) {
                data.push(root.model.get(i));
            }
            var jsonStr = JSON.stringify(data);
            
            // 2. 传给 Python 脚本保存
            root.saveProcess.command = ["python3", root.scriptPath, "save", jsonStr];
            root.saveProcess.running = true;
        }
    }

    // ================= 4. 通知服务监听 =================
    property var server: NotificationServer {
        onNotification: (n) => {
            if (n.desktopEntry === "spotify" || n.desktopEntry.includes("player")) return;

            let finalImage = "";
            let iconName = n.appIcon || n.desktopEntry || n.icon || "";
            
            let isPrivacyApp = false;
            for(let app of root.privacyApps) {
                if(n.desktopEntry && n.desktopEntry.toLowerCase().includes(app)) isPrivacyApp = true;
            }

            if (!isPrivacyApp && n.image && (n.image.startsWith("/") || n.image.startsWith("file://"))) {
                 finalImage = n.image.startsWith("/") ? "file://" + n.image : n.image;
            } else if (iconName !== "") {
                if (iconName.startsWith("/") || iconName.startsWith("file://")) {
                    finalImage = iconName.startsWith("/") ? "file://" + iconName : iconName;
                } else {
                    finalImage = "image://icon/" + iconName;
                }
            }

            // 插入数据
            root.model.insert(0, {
                "id": n.id,
                "appName": n.appName || "System",
                "summary": n.summary,
                "body": n.body,
                "imagePath": finalImage,
                "desktopEntry": n.desktopEntry,
                "time": new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
            });

            // 数量限制
            if (root.model.count > root.maxCount) {
                root.model.remove(root.model.count - 1);
            }
            
            // 【关键】数据变化，触发保存
            root.requestSave();
        }
    }

    // ================= 5. 公共操作方法 =================
    function clear() {
        model.clear();
        requestSave(); // 清空后立即保存
    }

    function remove(index) {
        if (index >= 0 && index < model.count) {
            model.remove(index);
            requestSave(); // 删除后保存
        }
    }
}
