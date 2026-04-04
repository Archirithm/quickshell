// config/NotificationStore.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property ListModel model: ListModel {}
    property int maxCount: 20
    property var privacyApps: ["qq", "wechat", "telegram", "discord"]
    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/notify_db.py"

    Component.onCompleted: {
        loadProcess.running = true
    }

    property var loadProcess: Process {
        command: ["python3", root.scriptPath, "load"]
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    var loaded = JSON.parse(data.trim());
                    root.model.clear();
                    for (var i = 0; i < loaded.length; i++) {
                        root.model.append(loaded[i]);
                    }
                } catch(e) {
                    console.log("Failed to load notifications:", e);
                }
            }
        }
    }

    property var saveProcess: Process {
        command: ["python3", root.scriptPath, "save", "[]"] 
    }

    function requestSave() {
        saveTimer.restart();
    }

    property var saveTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: {
            var data = [];
            for (var i = 0; i < root.model.count; i++) {
                data.push(root.model.get(i));
            }
            var jsonStr = JSON.stringify(data);
            root.saveProcess.command = ["python3", root.scriptPath, "save", jsonStr];
            root.saveProcess.running = true;
        }
    }

    // ============================================================
    // 供 Manager 调用的数据写入接口
    // ============================================================
    function addRecord(id, appName, summary, body, finalImage, desktopEntry) {
        root.model.insert(0, {
            "id": id,
            "appName": appName || "System",
            "summary": summary,
            "body": body,
            "imagePath": finalImage,
            "desktopEntry": desktopEntry || "",
            "time": new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
        });
        
        if (root.model.count > root.maxCount) {
            root.model.remove(root.model.count - 1);
        }
        
        root.requestSave(); 
    }

    function clear() {
        model.clear();
        requestSave(); 
    }

    function remove(index) {
        if (index >= 0 && index < model.count) {
            model.remove(index);
            requestSave(); 
        }
    }
}
