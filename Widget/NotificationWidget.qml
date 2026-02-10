import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import qs.config
import qs.Widget.common

SlideWindow {
    id: root
    title: "通知中心"
    icon: "\uf0f3" 
    windowHeight: 560
    
    // 【核心排版逻辑】
    // 自动避让：如果网络开了，往下挪 430；如果音频开了，再往下挪 370
    // 这样无论那两个组件开没开，通知组件总是在它们的最下方
    extraTopMargin: (WidgetState.networkOpen ? 430 : 0) + (WidgetState.audioOpen ? 370 : 0)
    
    // 同步状态到全局
    onIsOpenChanged: WidgetState.notifOpen = isOpen

    // --- 顶部工具栏 (一键清除) ---
    headerTools: Text {
        // 需要本地 Theme
        Theme { id: theme }
        
        text: "\uf1f8" // 垃圾桶图标
        font.family: "Font Awesome 6 Free Solid"
        font.pixelSize: 18
        
        // 有通知时变红，没通知时灰色半透明
        color: notifModel.count > 0 ? theme.error : theme.subtext
        opacity: notifModel.count > 0 ? 1 : 0.5
        
        MouseArea { 
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            // 点击清除所有通知
            onClicked: notifModel.clear()
        }
    }

    // --- 核心逻辑 ---
    ListModel { id: notifModel }

    NotificationServer {
        id: server
        
        onNotification: (n) => {
            // 1. 过滤掉播放器 (Spotify 等)
            if (n.desktopEntry === "spotify" || n.desktopEntry.includes("player")) return;
            
            // 2. 数量限制 (保留最近 20 条)
            if (notifModel.count >= 20) notifModel.remove(0);

            // ====================================================
            // 3. 【智能图标策略】
            // ====================================================
            const forceIconApps = [
                "qq", "com.tencent.qq", "linuxqq",
                "wechat", "com.tencent.wechat", "electronic-wechat",
                "telegram", "org.telegram.desktop", "telegram-desktop"
            ];
            
            const shouldForceIcon = forceIconApps.includes(n.desktopEntry.toLowerCase());
            let finalImage = "";

            // 分支 A: 允许显示图片 (截图、非黑名单App)
            if (!shouldForceIcon && n.image && (n.image.startsWith("/") || n.image.startsWith("file://"))) {
                 finalImage = n.image.startsWith("/") ? "file://" + n.image : n.image;
            } 
            // 分支 B: 强制显示 App Logo
            else {
                let iconName = n.appIcon || n.desktopEntry || n.icon || "";
                
                if (iconName !== "") {
                    if (iconName.startsWith("/") || iconName.startsWith("file://")) {
                        finalImage = iconName.startsWith("/") ? "file://" + iconName : iconName;
                    } else {
                        // 标准图标加载方式
                        finalImage = "image://icon/" + iconName;
                    }
                } else {
                    // 没有图标
                    finalImage = ""; 
                }
            }
            
            // 插入到最前面
            notifModel.insert(0, {
                "id": n.id,
                "appName": n.appName || "System",
                "summary": n.summary,
                "body": n.body,
                "imagePath": finalImage,
                "time": new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
            });
        }
    }

    // --- 界面内容 ---
    
    // 空状态提示
    Text {
        Theme { id: bgTheme }
        anchors.centerIn: parent
        visible: notifModel.count === 0
        text: "没有新通知"
        color: bgTheme.subtext
        font.pixelSize: 14
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 8
        
        model: notifModel

        delegate: Rectangle {
            Theme { id: itemTheme }

            width: ListView.view.width
            // 高度自适应：最小 60，如果文字多就撑开
            height: Math.max(60, contentLayout.height + 20)
            radius: 8
            color: "transparent"
            
            // 悬停高亮边框
            border.width: 1
            border.color: ma.containsMouse ? itemTheme.primary : "transparent"
            Behavior on border.color { ColorAnimation { duration: 150 } }

            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                // --- 图标区域 ---
                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    width: 40; height: 40
                    radius: 8
                    color: Qt.rgba(itemTheme.text.r, itemTheme.text.g, itemTheme.text.b, 0.1)
                    
                    // 图片图标
                    Image {
                        id: img
                        anchors.fill: parent
                        anchors.margins: 4
                        source: model.imagePath
                        fillMode: Image.PreserveAspectFit
                        visible: model.imagePath !== "" && status === Image.Ready
                    }
                    
                    // 默认气泡图标 (当没有图片或图片加载失败时显示)
                    Text {
                        anchors.centerIn: parent
                        visible: model.imagePath === "" || img.status === Image.Error
                        text: "\uf0e5" // 气泡图案
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 20
                        color: itemTheme.subtext
                    }
                }

                // --- 文字内容 ---
                ColumnLayout {
                    id: contentLayout
                    Layout.fillWidth: true
                    spacing: 2
                    
                    // 标题行：应用名 + 时间
                    RowLayout {
                        Layout.fillWidth: true
                        Text { 
                            text: model.appName
                            font.bold: true
                            font.pixelSize: 11
                            color: itemTheme.primary
                        }
                        Item { Layout.fillWidth: true }
                        Text { 
                            text: model.time
                            font.pixelSize: 10
                            color: itemTheme.subtext
                        }
                    }

                    // 摘要 (加粗)
                    Text {
                        text: model.summary
                        font.bold: true
                        font.pixelSize: 13
                        color: itemTheme.text
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // 正文 (支持换行，最多3行)
                    Text {
                        text: model.body
                        font.pixelSize: 12
                        color: itemTheme.subtext
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                
                // --- 单条删除按钮 (悬停显示) ---
                Text {
                    visible: ma.containsMouse
                    text: "\uf00d" // 叉号
                    font.family: "Font Awesome 6 Free Solid"
                    color: itemTheme.subtext
                    Layout.alignment: Qt.AlignTop
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notifModel.remove(index)
                    }
                }
            }
        }
    }
}
