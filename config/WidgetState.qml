pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root 

    property bool qsOpen: false
    property string qsView: "network"

    // 左侧边栏状态
    property bool leftSidebarOpen: false
    property string leftSidebarView: "info" // 可选值: "info", "sys", "weather"

    property bool notifOpen: false
    property bool notifIsHovered: false 
    // 【新增】：通知面板是否被固定
    property bool notifPinned: false 
    property string notifCurrentView: "main" 
    property string notifDetailAppId: ""
    property string notifDisplayMode: "compact" 

    // 设置每个 App 最多保留的历史消息数量
    property int maxMessagesPerApp: 50

    property bool hotCornerEnabled: true
    function openNotifPanelFromHotCorner() {
        if (hotCornerEnabled && !notifOpen) {
            notifOpen = true;
        }
    }

    property var notifAppCounts: {
        "system": 0, "qq": 0, "wechat": 0, "telegram": 0, "discord": 0
    }

    property var notifMessages: {
        "system": [], "qq": [], "wechat": [], "telegram": [], "discord": []
    }

    signal notifDataChanged();

    // ============================================================
    // 【持久化存储：Quickshell Process 官方规范版】
    // ============================================================
    readonly property string dbScriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/notify_db.py"

    property var loadProcess: Process {
        command: ["python3", root.dbScriptPath, "load"]
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    var output = data.trim();
                    if (!output || output === "[]" || output === "{}") return;

                    var loaded = JSON.parse(output);
                    var mockMsgs = { "system": [], "qq": [], "wechat": [], "telegram": [], "discord": [] };
                    var mockCounts = { "system": 0, "qq": 0, "wechat": 0, "telegram": 0, "discord": 0 };

                    if (Array.isArray(loaded)) {
                        for (var i = 0; i < loaded.length; i++) {
                            var item = loaded[i];
                            var aId = "system";

                            var nameStr = (item.appName || "").toLowerCase() + " " + (item.desktopEntry || "").toLowerCase() + " " + (item.summary || "").toLowerCase();
                            if (nameStr.indexOf("qq") !== -1) aId = "qq";
                            else if (nameStr.indexOf("wechat") !== -1 || nameStr.indexOf("微信") !== -1) aId = "wechat";
                            else if (nameStr.indexOf("telegram") !== -1) aId = "telegram";
                            else if (nameStr.indexOf("discord") !== -1) aId = "discord";

                            var ts = item.timestamp || item.time;
                            if (typeof ts === "string" || isNaN(ts)) {
                                ts = Date.now() - i * 1000; 
                            }

                            var notifObj = {
                                id: item.id !== undefined ? item.id : Date.now() + i,
                                title: item.summary || item.appName || "新通知",
                                body: item.body || "",
                                timestamp: ts,
                                appId: aId,
                                _raw: item 
                            };
                            
                            mockMsgs[aId].push(notifObj);
                            mockCounts[aId]++;
                        }
                    }

                    root.notifMessages = mockMsgs;
                    root.notifAppCounts = mockCounts;
                    root.notifDataChanged();
                    console.log("本地通知加载成功！数量: " + loaded.length);
                } catch(e) {
                    console.log("解析通知失败: " + e);
                }
            }
        }
    }

    property var saveProcess: Process {
        command: ["python3", root.dbScriptPath, "save", "[]"] 
    }

    property var saveTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: {
            var all = root.getAllMessages(); 
            var allToSave = [];
            
            for (var i = 0; i < all.length; i++) {
                var m = all[i];
                if (m._raw) {
                    allToSave.push(m._raw);
                } else {
                    var appName = "System";
                    if (m.appId === "qq") appName = "QQ";
                    if (m.appId === "wechat") appName = "WeChat";
                    if (m.appId === "telegram") appName = "Telegram";
                    if (m.appId === "discord") appName = "Discord";
                    
                    allToSave.push({
                        id: m.id,
                        appName: appName,
                        summary: m.title,
                        body: m.body,
                        timestamp: m.timestamp,
                        time: m.timestamp,
                        imagePath: "",
                        desktopEntry: ""
                    });
                }
            }
            
            var jsonStr = JSON.stringify(allToSave);
            root.saveProcess.command = ["python3", root.dbScriptPath, "save", jsonStr];
            root.saveProcess.running = true;
        }
    }

    function requestSave() {
        saveTimer.restart();
    }

    Component.onCompleted: {
        loadProcess.running = true;
    }

    // ============================================================
    // 【核心数据操作 API】
    // ============================================================
    function addRealNotification(appId, notifData) {
        var mockCounts = JSON.parse(JSON.stringify(notifAppCounts));
        var mockMsgs = JSON.parse(JSON.stringify(notifMessages));
        if (!mockMsgs[appId]) mockMsgs[appId] = []; 
        
        mockMsgs[appId].unshift(notifData);
        
        // 超出上限则剔除最旧消息
        while (mockMsgs[appId].length > maxMessagesPerApp) {
            mockMsgs[appId].pop();
        }

        mockCounts[appId] = mockMsgs[appId].length;

        notifMessages = mockMsgs;
        notifAppCounts = mockCounts;
        notifDataChanged();
        
        requestSave(); 
    }

    function dismissMessage(appId, messageId) {
        var mockCounts = JSON.parse(JSON.stringify(notifAppCounts));
        var mockMsgs = JSON.parse(JSON.stringify(notifMessages));
        
        if (mockMsgs[appId]) {
            mockMsgs[appId] = mockMsgs[appId].filter(function(msg) {
                return msg.id !== messageId;
            });
            mockCounts[appId] = mockMsgs[appId].length;
            
            notifMessages = mockMsgs; 
            notifAppCounts = mockCounts; 
            notifDataChanged();
            
            if (mockMsgs[appId].length === 0) {
                notifCurrentView = "main";
            } 
            
            requestSave(); 
        }
    }

    function getAllMessages() {
        var all = [];
        for (var appId in notifMessages) {
            var msgs = notifMessages[appId];
            if (msgs) {
                for (var i = 0; i < msgs.length; i++) {
                    var msgCopy = JSON.parse(JSON.stringify(msgs[i]));
                    msgCopy.appId = appId; 
                    all.push(msgCopy);
                }
            }
        }
        all.sort(function(a, b) {
            var tA = a.timestamp || 0;
            var tB = b.timestamp || 0;
            return tB - tA; 
        });
        return all;
    }

    function closeAllPopups() {
        qsOpen = false;
        leftSidebarOpen = false;
    }
}
