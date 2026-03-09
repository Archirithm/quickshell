import QtQuick
import Quickshell
import Quickshell.Io  
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.Services
import qs.config

import qs.Modules.DynamicIsland.ClockContent
import qs.Modules.DynamicIsland.MediaContent  
import qs.Modules.DynamicIsland.NotificationContent
import qs.Modules.DynamicIsland.VolumeContent
import qs.Modules.DynamicIsland.LauncherContent
import qs.Modules.DynamicIsland.DashboardContent
import qs.Modules.DynamicIsland.LyricsContent 
import qs.Modules.DynamicIsland.Hub

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: islandWindow
        required property var modelData
        screen: modelData

        property int earRadius: 16 

        // ============================================================
        // 【Ambxst 魔法 1】：外层 Wayland 窗口尺寸彻底静止锁死
        // 彻底霸占屏幕宽度，高度写死为最大可能展开的高度（比如 500），预留充足变形空间。
        // 因为尺寸绝对静止，Wayland 不会进行任何重绘计算 = 零抽搐！
        // ============================================================
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: Screen.height 
        margins { top: 0 } 
        
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay

        WlrLayershell.keyboardFocus: (root.showLauncher || root.showDashboard || root.showHub)
            ? WlrKeyboardFocus.Exclusive 
            : WlrKeyboardFocus.None

        // ============================================================
        // 【Ambxst 魔法 2】：动态物理点击穿透遮罩
        // 告诉 Wayland：在这个 500px 高的巨大透明窗口里，只有 maskContainer 的区域可以拦截点击，
        // 剩下的透明部分，鼠标点击必须穿透给背后的顶栏和桌面！
        // ============================================================
        mask: Region {
            item: maskContainer
        }

        // 把灵动岛本体和猫耳朵包裹在一起，作为碰撞遮罩的目标
        Item {
            id: maskContainer
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            // 宽度和高度严格跟随灵动岛本体和猫耳
            width: root.width + (islandWindow.earRadius * 2)
            height: root.height

            // --- 1. 左侧猫耳朵 ---
            Canvas {
                id: leftEar
                anchors.right: root.left
                anchors.top: root.top
                width: islandWindow.earRadius
                height: islandWindow.earRadius
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = Colorscheme.background;
                    ctx.beginPath();
                    ctx.moveTo(0, 0);                 
                    ctx.lineTo(width, 0);             
                    ctx.lineTo(width, height);        
                    ctx.arc(0, height, width, 0, -Math.PI/2, true);
                    ctx.fill();
                }
                Connections {
                    target: Colorscheme
                    function onBackgroundChanged() { leftEar.requestPaint() }
                }
            }

            // --- 2. 灵动岛本体 ---
            Rectangle {
                id: root
                // 本体在遮罩容器的正中间展开
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter

                // ================= 状态定义 =================
                property bool showDashboard: false
                property bool showLauncher: false
                property bool showLyrics: false 
                property bool expanded: false
                property bool showVolume: false
                
                property bool showHub: false
                property int hubTabIndex: 0 

                // ================= 互斥模式判定 =================
                property bool isDashboardMode: showDashboard
                property bool isLyricsMode: showLyrics && !showDashboard
                property bool isLauncherMode: showLauncher && !isLyricsMode && !showDashboard
                property bool isHubMode: showHub && !isLauncherMode && !isLyricsMode && !showDashboard
                property bool isVolumeMode: showVolume && !expanded && !isHubMode && !isLauncherMode && !isLyricsMode && !showDashboard
                property bool isNotifMode: notifManager.hasNotifs && !expanded && !showVolume && !isHubMode && !isLauncherMode && !isLyricsMode && !showDashboard

                // ================= 尺寸定义 =================
                property int dashW: 810; property int dashH: 420
                property int launchW: 400; property int launchH: 420 
                property int lyricsW: 480; property int lyricsH: 42 
                property int expandedW: 540; property int expandedH: 210
                property int collapsedW: 220; property int collapsedH: 42 
                property int notifW: 380; property int notifH: (notifManager.model.count * 70) + 20
                property int volW: 220; property int volH: 40
                
                // ================= 视觉与基础属性 =================
                color: Colorscheme.background
                clip: true
                z: 100
            
                radius: (expanded || isNotifMode || isVolumeMode || isLauncherMode || 
                        isDashboardMode || isLyricsMode || isHubMode) 
                        ? 24 : 16 

                width: isDashboardMode ? dashW : 
                    isHubMode       ? hub.implicitWidth : 
                    isLyricsMode    ? lyricsW : 
                    isLauncherMode  ? launchW : 
                    expanded        ? expandedW : 
                    isVolumeMode    ? volW : 
                    isNotifMode     ? notifW : collapsedW

                height: isDashboardMode ? dashH : 
                        isHubMode       ? hub.implicitHeight : 
                        isLyricsMode    ? lyricsH : 
                        isLauncherMode  ? launchH : 
                        expanded        ? expandedH : 
                        isVolumeMode    ? volH : 
                        isNotifMode     ? notifH : collapsedH

                // 填缝魔法
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.radius
                    color: parent.color
                    z: -1
                }

                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
                Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
                Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }

                // ================= IPC 通信处理 =================
                IpcHandler {
                    target: "island"
                    
                    function closeAllOthers() {
                        root.showDashboard = false;
                        root.showLauncher = false;
                        root.showLyrics = false;
                        root.expanded = false;
                    }

                    function dashboard() {
                        if (root.showDashboard) { root.showDashboard = false; return "DASHBOARD_CLOSED" } 
                        else { closeAllOthers(); root.showHub = false; root.showDashboard = true; return "DASHBOARD_OPENED" }
                    }
                    
                    function launcher() {
                        if (root.showLauncher) { root.showLauncher = false; return "LAUNCHER_CLOSED" } 
                        else { closeAllOthers(); root.showHub = false; root.showLauncher = true; return "LAUNCHER_OPENED" }
                    }

                    function hub() {
                        if (root.showHub) { 
                            root.showHub = false; return "HUB_CLOSED" 
                        } else { 
                            closeAllOthers(); root.showHub = true; return "HUB_OPENED" 
                        }
                    }
                }

                // ================= 音频与通知 =================
                PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }
                property var audioNode: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

                Timer { id: volHideTimer; interval: 2000; onTriggered: root.showVolume = false }
                
                Connections {
                    target: root.audioNode; ignoreUnknownSignals: true
                    function onVolumeChanged() { triggerVolumeOSD() }
                    function onMutedChanged() { triggerVolumeOSD() }
                }
            
                function triggerVolumeOSD() {
                    if (root.showDashboard || root.showHub || root.showLauncher || root.expanded || root.showLyrics) return
                    root.showVolume = true; volHideTimer.restart()
                }

                NotificationManager { id: notifManager }
                
                // ================= 媒体播放器逻辑 =================
                property var currentPlayer: null

                Timer {
                    id: stickyTimer
                    interval: 500; repeat: true; triggeredOnStart: true
                    running: Mpris.players.values.length > 0
                    onRunningChanged: { if (!running) root.currentPlayer = null }
                    onTriggered: {
                        var players = Mpris.players.values
                        if (players.length === 0) { root.currentPlayer = null; return }
                        var playingPlayer = null
                        for (let i = 0; i < players.length; i++) { 
                            if (players[i].isPlaying) { playingPlayer = players[i]; break } 
                        }
                        if (playingPlayer) { 
                            if (root.currentPlayer !== playingPlayer) root.currentPlayer = playingPlayer 
                        } else {
                            var currentIsValid = false
                            if (root.currentPlayer) { 
                                for (let i = 0; i < players.length; i++) { 
                                    if (players[i] === root.currentPlayer) { currentIsValid = true; break } 
                                } 
                            }
                            if (!currentIsValid) root.currentPlayer = players[0]
                        }
                    }
                }

                // ================= 全局鼠标交互 =================
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: !isNotifMode && !isVolumeMode
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton) {
                            if (root.showDashboard) root.showDashboard = false
                            else if (root.showHub) root.showHub = false 
                            else if (root.showLauncher) root.showLauncher = false
                            
                            root.showLyrics = !root.showLyrics
                            if (root.showLyrics) root.expanded = false
                        } else {
                            if (root.showDashboard) root.showDashboard = false
                            else if (root.showLyrics) root.showLyrics = false 
                            else if (root.showLauncher) root.showLauncher = false
                            else if (root.showHub) root.showHub = false   
                            else root.expanded = !root.expanded
                        }
                    }
                }

                // ================= 内部组件挂载区 =================
                Item {
                    id: staticCanvas
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 1600 
                    height: 1200

                    ClockContent { 
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.collapsedW
                        height: root.collapsedH
                        
                        player: root.currentPlayer
                        opacity: (!root.expanded && !root.isNotifMode && !root.isVolumeMode && !root.isLauncherMode && !root.isDashboardMode && !root.isLyricsMode && !root.isHubMode) ? 1 : 0
                        visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 200 } } 
                    }
                        
                    VolumeContent { 
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.volW
                        height: root.volH

                        audioNode: root.audioNode
                        opacity: root.isVolumeMode ? 1 : 0
                        visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 200 } } 
                    }
                        
                    NotificationContent { 
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: 10
                        width: root.notifW - 20
                        height: root.notifH - 20

                        manager: notifManager
                        opacity: root.isNotifMode ? 1 : 0
                        visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 200 } } 
                    }
                        
                    LyricsContent { 
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.lyricsW
                        height: root.lyricsH

                        player: root.currentPlayer; active: root.isLyricsMode
                        opacity: root.isLyricsMode ? 1 : 0
                        visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 200 } } 
                    }
                    
                    MediaContent { 
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: 20
                        width: root.expandedW - 40
                        height: root.expandedH - 40

                        player: root.expanded ? root.currentPlayer : null
                        opacity: (root.expanded && !root.isLyricsMode && !root.isHubMode) ? 1 : 0
                        visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 200 } } 
                    }

                    LauncherContent { 
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.launchW
                        height: root.launchH

                        onLaunchRequested: root.showLauncher = false
                        opacity: root.isLauncherMode ? 1 : 0
                        visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 200 } } 
                    }
                        
                    DashboardContent { 
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.dashW
                        height: root.dashH

                        opacity: root.isDashboardMode ? 1 : 0
                        visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 200 } } 
                    }
                        
                    HubContent {
                        id: hub
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: implicitWidth
                        height: implicitHeight
                        
                        player: root.currentPlayer
                        currentIndex: root.hubTabIndex
                        onCurrentIndexChanged: root.hubTabIndex = currentIndex
                        onCloseRequested: root.showHub = false

                        opacity: root.isHubMode ? 1 : 0
                        visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }
            }

            // --- 3. 右侧猫耳朵 ---
            Canvas {
                id: rightEar
                anchors.left: root.right
                anchors.top: root.top
                width: islandWindow.earRadius
                height: islandWindow.earRadius
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = Colorscheme.background;
                    ctx.beginPath();
                    ctx.moveTo(width, 0);             
                    ctx.lineTo(0, 0);                 
                    ctx.lineTo(0, height);            
                    ctx.arc(width, height, width, Math.PI, Math.PI*1.5, false);
                    ctx.fill();
                }
                Connections {
                    target: Colorscheme
                    function onBackgroundChanged() { rightEar.requestPaint() }
                }
            }
        }
    }
}
