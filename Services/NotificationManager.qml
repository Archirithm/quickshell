pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.Modules.DynamicIsland.OverviewContent 

Item {
    id: root

    property alias model: popupList           
    property bool hasNotifs: popupList.count > 0 
    
    property alias sysHistoryModel: sysHistoryList 
    property alias appHistoryModel: appHistoryList 

    ListModel { id: popupList }
    ListModel { id: sysHistoryList }
    ListModel { id: appHistoryList }

    NotificationServer {
        id: server
        
        onNotification: (n) => {
            if (n.desktopEntry === "spotify" || n.desktopEntry.includes("player")) return;

            const imApps = [
                "qq", "com.tencent.qq", "linuxqq",
                "wechat", "com.tencent.wechat", "electronic-wechat",
                "telegram", "org.telegram.desktop", "telegram-desktop",
                "discord", "slack", "element"
            ];
            
            let appNameLower = (n.desktopEntry || n.appName || "").toLowerCase();
            const isIMApp = imApps.includes(appNameLower) || 
                            appNameLower.includes("qq") || 
                            appNameLower.includes("wechat") || 
                            appNameLower.includes("telegram") || 
                            appNameLower.includes("discord");

            let finalImage = "";
            let homePath = Quickshell.env("HOME") || "/home/archirithm";

            if (appNameLower.includes("qq")) {
                finalImage = "file://" + homePath + "/.config/quickshell/assets/apps/qq.svg";
            } else if (appNameLower.includes("wechat")) {
                finalImage = "file://" + homePath + "/.config/quickshell/assets/apps/wechat.svg";
            } else if (appNameLower.includes("discord")) {
                finalImage = "file://" + homePath + "/.config/quickshell/assets/apps/discord.svg";
            } else if (appNameLower.includes("telegram")) {
                finalImage = "file://" + homePath + "/.config/quickshell/assets/apps/telegram.svg";
            } 
            else if (!isIMApp && n.image && (n.image.startsWith("/") || n.image.startsWith("file://"))) {
                finalImage = n.image.startsWith("/") ? "file://" + n.image : n.image;
            } else {
                let iconName = n.appIcon || n.desktopEntry || n.icon || "";
                if (iconName !== "") {
                    if (iconName.startsWith("/") || iconName.startsWith("file://")) {
                        finalImage = iconName.startsWith("/") ? "file://" + iconName : iconName;
                    } else {
                        finalImage = "icon:" + iconName;
                    }
                }
            }

            // 【核心修复 1】：将 id 改名为 notifId，防止在 QML UI 引擎中引起 id 关键字冲突
            let notifData = {
                "notifId": n.id,
                "summary": n.summary,
                "body": n.body,
                "imagePath": finalImage,
                "time": Qt.formatTime(new Date(), "hh:mm")
            };

            if (isIMApp) {
                appHistoryList.insert(0, notifData);
                if (appHistoryList.count > 20) appHistoryList.remove(20);
            } else {
                sysHistoryList.insert(0, notifData);
                if (sysHistoryList.count > 20) sysHistoryList.remove(20);
            }

            if (!ControlBackend.dndEnabled) {
                popupList.insert(0, notifData);
                if (popupList.count > 3) popupList.remove(3);
                // 【核心修复 2】：去掉了这里的 dismissTimer.restart()，把生命周期管理权交给前端卡片
            }
        }
    }

    // 【核心修复 3】：新增唯一的 ID 追踪销毁机制，无论队列怎么上下排挤，都能精准删掉倒计时结束的那条
    function removeByNotifId(targetId) {
        for (let i = 0; i < popupList.count; i++) {
            if (popupList.get(i).notifId === targetId) {
                popupList.remove(i);
                break;
            }
        }
    }
    
    function removeSysHistory(index) {
        if (index >= 0 && index < sysHistoryList.count) sysHistoryList.remove(index);
    }

    function removeAppHistory(index) {
        if (index >= 0 && index < appHistoryList.count) appHistoryList.remove(index);
    }

    function clearAllHistory() {
        sysHistoryList.clear();
        appHistoryList.clear();
    }
}
