import QtQuick
import Qt5Compat.GraphicalEffects 
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

        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: Screen.height 
        margins { top: 0 } 
        
        color: "transparent"
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Top

        WlrLayershell.keyboardFocus: (root.showLauncher || root.showDashboard || root.showHub)
            ? WlrKeyboardFocus.Exclusive 
            : WlrKeyboardFocus.None

        mask: Region {
            item: maskContainer
        }

        // ============================================================
        // 【阴影源 (Shadow Source)】
        // ============================================================
        Item {
            id: shadowSource
            anchors.top: maskContainer.top
            anchors.horizontalCenter: maskContainer.horizontalCenter
            width: maskContainer.width
            height: maskContainer.height
            visible: false 

            // 替身 1：左侧猫耳
            Canvas {
                id: shadowLeftEar 
                anchors.right: rootShadow.left
                anchors.top: rootShadow.top
                width: islandWindow.earRadius
                height: islandWindow.earRadius
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset(); ctx.fillStyle = "black";
                    ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(width, 0); ctx.lineTo(width, height);
                    ctx.arc(0, height, width, 0, -Math.PI/2, true); ctx.fill();
                }
                Connections { 
                    target: Colorscheme; function onBackgroundChanged() { shadowLeftEar.requestPaint() }
                }
            }

            // 替身 2：灵动岛本体
            Rectangle {
                id: rootShadow
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.width
                height: root.height
                radius: root.radius
                color: "black"
                
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.radius
                    color: "black"
                    z: -1
                }
            }

            // 替身 3：右侧猫耳
            Canvas {
                id: shadowRightEar 
                anchors.left: rootShadow.right
                anchors.top: rootShadow.top
                width: islandWindow.earRadius
                height: islandWindow.earRadius
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset(); ctx.fillStyle = "black";
                    ctx.beginPath(); ctx.moveTo(width, 0); ctx.lineTo(0, 0); ctx.lineTo(0, height);
                    ctx.arc(width, height, width, Math.PI, Math.PI*1.5, false); ctx.fill();
                }
                Connections { 
                    target: Colorscheme; function onBackgroundChanged() { shadowRightEar.requestPaint() } 
                }
            }
        }

        // ============================================================
        // 【阴影渲染 (DropShadow)】
        // ============================================================
        DropShadow {
            anchors.fill: shadowSource
            source: shadowSource
            horizontalOffset: 0
            verticalOffset: 6
            radius: 20
            samples: 32
            color: "#80000000" 
            cached: true
        }

        // ============================================================
        // 【原始灵动岛本体 (原封不动)】
        // ============================================================
        Item {
            id: maskContainer
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
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
                    var ctx = getContext("2d"); ctx.reset();
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
                property bool isCollapsedMode: !expanded && !isNotifMode && !isVolumeMode && !isLauncherMode && !isDashboardMode && !isLyricsMode && !isHubMode

                // ================= 尺寸定义 =================
                property int dashW: 810; property int dashH: 420
                property int launchW: 400; property int launchH: 420 
                
                // 【核心修改】：绑定歌词组件的动态宽度
                property int lyricsW: lyricsWidget.implicitWidth; property int lyricsH: 42 
                
                property int expandedW: 540; property int expandedH: 210
                property int collapsedW: 220; property int collapsedH: 42 
                property int notifW: 380; property int notifH: (notifManager.model.count * 70) + 20
                property int volW: 220; property int volH: 40
                
                // ================= 视觉与基础属性 =================
                color: Colorscheme.background
                clip: true
                z: 100

                // ================= 目标尺寸与防时序错乱重构 =================
                property int targetR: (expanded || isNotifMode || isVolumeMode || isLauncherMode || 
                        isDashboardMode || isLyricsMode || isHubMode) 
                        ? 24 : (isCollapsedMode && islandMouseArea.containsMouse ? 18 : 16) 

                property int targetW: isDashboardMode ? dashW : 
                    isHubMode       ? hub.implicitWidth : 
                    isLyricsMode    ? lyricsW : 
                    isLauncherMode  ? launchW : 
                    expanded        ? expandedW : 
                    isVolumeMode    ? volW : 
                    isNotifMode     ? notifW : (collapsedW + (isCollapsedMode && islandMouseArea.containsMouse ? 16 : 0))

                property int targetH: isDashboardMode ? dashH : 
                        isHubMode       ? hub.implicitHeight : 
                        isLyricsMode    ? lyricsH : 
                        isLauncherMode  ? launchH : 
                        expanded        ? expandedH : 
                        isVolumeMode    ? volH : 
                        isNotifMode     ? notifH : (collapsedH + (isCollapsedMode && islandMouseArea.containsMouse ? 6 : 0))

                // ================= 状态与物理锁 =================
                property real wDamping: 1.0
                property real hDamping: 1.0
                property real rDamping: 1.0

                // 恢复 QML 原生的声明式绑定
                width: targetW
                height: targetH
                radius: targetR

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.radius
                    color: parent.color
                    z: -1
                }

                // ================= 动态阻尼控制 =================
                onTargetWChanged: {
                    let isExpanding = (targetW > width); wDamping = isExpanding ? 0.7 : 0.8; 
                }
                
                onTargetHChanged: {
                    let isExpanding = (targetH > height); hDamping = isExpanding ? 0.7 : 0.8;
                }
                
                onTargetRChanged: {
                    let isExpanding = (targetR > radius); rDamping = isExpanding ? 0.7 : 0.8;
                }

                // ================= 官方正统物理引擎 =================
                Behavior on width { 
                    SpringAnimation { 
                        spring: 5.0      
                        mass: 3.6        
                        damping: root.wDamping 
                        epsilon: 0.01    
                    } 
                }
                Behavior on height { 
                    SpringAnimation { 
                        spring: 5.0
                        mass: 3.6
                        damping: root.hDamping
                        epsilon: 0.01 
                    } 
                }
                Behavior on radius { 
                    SpringAnimation { 
                        spring: 5.0
                        mass: 3.6
                        damping: root.rDamping
                        epsilon: 0.01 
                    } 
                }

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
                    function onVolumeChanged() { root.triggerVolumeOSD() } 
                    function onMutedChanged() { root.triggerVolumeOSD() }  
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
                    id: islandMouseArea  
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    
                    hoverEnabled: true   
                    
                    enabled: !root.isNotifMode && !root.isVolumeMode 
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
                        
                    // 【核心修改】：添加 ID
                    LyricsContent { 
                        id: lyricsWidget 
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
                    var ctx = getContext("2d"); ctx.reset();
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
