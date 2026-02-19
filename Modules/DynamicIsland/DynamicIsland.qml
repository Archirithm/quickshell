import QtQuick
import Quickshell
import Quickshell.Io  // 引入 IPC 模块
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.Services
import qs.config
import qs.Modules.DynamicIsland.ClockContent
import qs.Modules.DynamicIsland.MediaContent
import qs.Modules.DynamicIsland.NotificationContent
import qs.Modules.DynamicIsland.VolumeContent
import qs.Modules.DynamicIsland.LauncherContent
import qs.Modules.DynamicIsland.WallpaperContent
import qs.Modules.DynamicIsland.DashboardContent
import qs.Modules.DynamicIsland.LyricsContent 

Rectangle {
    id: root

    // ================= 状态定义 =================
    property bool showDashboard: false
    property bool showWallpaper: false
    property bool showLauncher: false
    property bool showLyrics: false 
    property bool expanded: false
    property bool showVolume: false

    // --- 优先级判断 ---
    property bool isDashboardMode: showDashboard
    property bool isWallpaperMode: showWallpaper && !showDashboard
    property bool isLyricsMode: showLyrics && !showDashboard && !showWallpaper
    property bool isLauncherMode: showLauncher && !showWallpaper && !showDashboard && !isLyricsMode
    property bool isVolumeMode: showVolume && !expanded && !showLauncher && !showWallpaper && !showDashboard && !isLyricsMode
    property bool isNotifMode: notifManager.hasNotifs && !expanded && !showVolume && !showLauncher && !showWallpaper && !showDashboard && !isLyricsMode

    // ================= 尺寸定义 =================
    property int dashW: 810;
    property int dashH: 240
    property int wallW: 810;
    property int wallH: 180
    property int launchW: 400;
    property int launchH: 500
    
    // 单行歌词胶囊尺寸 (480x42)
    property int lyricsW: 480
    property int lyricsH: 42 
    
    property int expandedW: 420;
    property int expandedH: 180
    property int collapsedW: 220;
    property int collapsedH: 32
    property int notifW: 380;
    property int notifH: (notifManager.model.count * 70) + 20
    property int volW: 220;
    property int volH: 40
    
    color: Colorsheme.background
    clip: true
    z: 100
    
    // 圆角逻辑
    radius: (expanded || isNotifMode || isVolumeMode || isLauncherMode || isWallpaperMode || isDashboardMode || isLyricsMode) ?
        24 : height / 2

    // 宽高动态切换
    width: isDashboardMode ?
        dashW : (isWallpaperMode ? wallW : (isLyricsMode ? lyricsW : (isLauncherMode ? launchW : (expanded ? expandedW : (isVolumeMode ? volW : (isNotifMode ? notifW : collapsedW))))))
    height: isDashboardMode ?
        dashH : (isWallpaperMode ? wallH : (isLyricsMode ? lyricsH : (isLauncherMode ? launchH : (expanded ? expandedH : (isVolumeMode ? volH : (isNotifMode ? notifH : collapsedH))))))

    // ================= 智能动画判断 =================
    // 技巧：展开时 isLauncherMode 为真；收起瞬间，虽然 isLauncherMode 为假，但此时面板高度还停留在 500，依然大于 400。
    // 这样能确保 App 启动器的“展开”和“收起”都是丝滑的，而其他小组件依然保持 Q 弹。
    property bool useSmoothAnim: root.isLauncherMode || root.height > 400

    // 完美的中心膨胀动画
    transform: Translate {
        y: isLyricsMode ? -((lyricsH - collapsedH) / 2) : 0
        Behavior on y { 
            NumberAnimation { 
                duration: 500
                // Y 轴位移基本只有歌词在用，保留弹簧
                easing.type: Easing.OutBack
                easing.overshoot: 1.0 
            } 
        }
    }

    Behavior on width { 
        NumberAnimation { 
            duration: root.useSmoothAnim ? 400 : 500
            easing.type: root.useSmoothAnim ? Easing.OutExpo : Easing.OutBack
            easing.overshoot: root.useSmoothAnim ? 0.0 : 1.0 
        } 
    }
    
    Behavior on height { 
        NumberAnimation { 
            duration: root.useSmoothAnim ? 400 : 500
            easing.type: root.useSmoothAnim ? Easing.OutExpo : Easing.OutBack
            easing.overshoot: root.useSmoothAnim ? 0.0 : 1.0 
        } 
    }
    
    Behavior on radius { 
        NumberAnimation { 
            duration: root.useSmoothAnim ? 400 : 500
            easing.type: root.useSmoothAnim ? Easing.OutExpo : Easing.OutBack
        } 
    }
    // ================= IPC 控制中心 (新) =================
    // 替代了原来的 Process 管道监听
    IpcHandler {
        target: "island"

        // 命令: quickshell ipc call island dashboard
        function dashboard() {
            if (root.showDashboard) {
                root.showDashboard = false
                return "DASHBOARD_CLOSED"
            } else {
                root.showLauncher = false
                root.showWallpaper = false
                root.expanded = false
                root.showLyrics = false
                root.showDashboard = true
                return "DASHBOARD_OPENED"
            }
        }

        // 命令: quickshell ipc call island wallpaper
        function wallpaper() {
            if (root.showWallpaper) {
                root.showWallpaper = false
                return "WALLPAPER_CLOSED"
            } else {
                root.showLauncher = false
                root.showDashboard = false
                root.expanded = false
                root.showLyrics = false
                root.showWallpaper = true
                return "WALLPAPER_OPENED"
            }
        }

        // 命令: quickshell ipc call island launcher
        // (对应旧版的 toggle 命令)
        function launcher() {
            // 确保先关闭其他大面板
            root.showDashboard = false
            root.showWallpaper = false
            
            if (root.showLauncher) {
                root.showLauncher = false
                return "LAUNCHER_CLOSED"
            } else {
                root.expanded = false
                root.showLyrics = false
                root.showLauncher = true
                return "LAUNCHER_OPENED"
            }
        }
    }

    // ================= 音频与通知服务 =================
    PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }
    property var audioNode: Pipewire.defaultAudioSink ?
        Pipewire.defaultAudioSink.audio : null

    Timer { id: volHideTimer; interval: 2000;
        onTriggered: root.showVolume = false }
    Connections {
        target: root.audioNode 
        ignoreUnknownSignals: true
        function onVolumeChanged() { triggerVolumeOSD() }
        function onMutedChanged() { triggerVolumeOSD() }
    }
    function triggerVolumeOSD() {
        if (root.showDashboard || root.showLauncher || root.showWallpaper || root.expanded || root.showLyrics) return;
        root.showVolume = true;
        volHideTimer.restart();
    }

    NotificationManager { id: notifManager }
    
    // ================= 粘性播放器逻辑 =================
    property var currentPlayer: null

    Timer {
        id: stickyTimer
        interval: 500
        repeat: true
        triggeredOnStart: true
        
        running: Mpris.players.values.length > 0
        
        onRunningChanged: {
            if (!running) root.currentPlayer = null
        }

        onTriggered: {
            var players = Mpris.players.values
            if (players.length === 0) {
                root.currentPlayer = null
                return
            }

            var playingPlayer = null
            for (let i = 0; i < players.length; i++) {
                if (players[i].isPlaying) { 
                    playingPlayer = players[i]
                    break
                }
            }

            if (playingPlayer) {
                if (root.currentPlayer !== playingPlayer) root.currentPlayer = playingPlayer
            } else {
                var currentIsValid = false
                if (root.currentPlayer) {
                    for (let i = 0; i < players.length; i++) {
                        if (players[i] === root.currentPlayer) {
                            currentIsValid = true
                            break
                        }
                    }
                }
                if (!currentIsValid) root.currentPlayer = players[0]
            }
        }
    }

    // ================= 交互逻辑 =================
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: !isNotifMode && !isVolumeMode
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                // 中键切换歌词 (保持原有逻辑，不走 IPC)
                if (root.showDashboard) root.showDashboard = false;
                else if (root.showWallpaper) root.showWallpaper = false;
                else if (root.showLauncher) root.showLauncher = false;
                root.showLyrics = !root.showLyrics;
                if (root.showLyrics) root.expanded = false;
            } 
            else {
                // 左键切换展开
                if (root.showDashboard) root.showDashboard = false;
                else if (root.showWallpaper) root.showWallpaper = false;
                else if (root.showLyrics) root.showLyrics = false;
                else if (root.showLauncher) root.showLauncher = false;
                else root.expanded = !root.expanded;
            }
        }
    }

    // ================= 视图内容 =================
    Item {
        anchors.fill: parent

        ClockContent {
            anchors.fill: parent
            player: root.currentPlayer
            opacity: (!root.expanded && !root.isNotifMode && !root.isVolumeMode && !root.isLauncherMode && !root.isWallpaperMode && !root.isDashboardMode && !root.isLyricsMode) ?
                1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        VolumeContent { 
            anchors.fill: parent;
            audioNode: root.audioNode; 
            opacity: root.isVolumeMode ? 1 : 0; visible: opacity > 0;
            Behavior on opacity { NumberAnimation { duration: 200 } } 
        }
        
        NotificationContent { 
            anchors.fill: parent;
            anchors.margins: 10; manager: notifManager; 
            opacity: root.isNotifMode ? 1 : 0; visible: opacity > 0;
            Behavior on opacity { NumberAnimation { duration: 200 } } 
        }
        
        LyricsContent {
            anchors.fill: parent
            player: root.currentPlayer
            active: root.isLyricsMode 
            opacity: root.isLyricsMode ?
                1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        
        MediaContent {
            anchors.fill: parent
            anchors.margins: 20
            player: root.expanded ? root.currentPlayer : null
            opacity: (root.expanded && !root.isLyricsMode) ?
                1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        
        LauncherContent { 
            anchors.fill: parent;
            onLaunchRequested: root.showLauncher = false; 
            opacity: root.isLauncherMode ? 1 : 0; visible: opacity > 0;
            Behavior on opacity { NumberAnimation { duration: 200 } } 
        }

        WallpaperContent {
            anchors.fill: parent
            onWallpaperChanged: root.showWallpaper = false
            opacity: root.isWallpaperMode ?
                1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        DashboardContent {
            anchors.fill: parent
            opacity: root.isDashboardMode ?
                1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
