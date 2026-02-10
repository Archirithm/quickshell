import QtQuick
import Quickshell
import Quickshell.Io
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
    property int dashW: 810; property int dashH: 240
    property int wallW: 810; property int wallH: 180
    property int launchW: 400; property int launchH: 500
    
    // 单行歌词胶囊尺寸 (480x42)
    property int lyricsW: 480
    property int lyricsH: 42 
    
    property int expandedW: 420; property int expandedH: 180
    property int collapsedW: 220; property int collapsedH: 32
    property int notifW: 380; property int notifH: (notifManager.model.count * 70) + 20
    property int volW: 220; property int volH: 40
    
    color: Colorsheme.background
    clip: true
    z: 100
    
    // 圆角逻辑
    radius: (expanded || isNotifMode || isVolumeMode || isLauncherMode || isWallpaperMode || isDashboardMode || isLyricsMode) ? 24 : height / 2

    // 宽高动态切换
    width: isDashboardMode ? dashW : (isWallpaperMode ? wallW : (isLyricsMode ? lyricsW : (isLauncherMode ? launchW : (expanded ? expandedW : (isVolumeMode ? volW : (isNotifMode ? notifW : collapsedW))))))
    height: isDashboardMode ? dashH : (isWallpaperMode ? wallH : (isLyricsMode ? lyricsH : (isLauncherMode ? launchH : (expanded ? expandedH : (isVolumeMode ? volH : (isNotifMode ? notifH : collapsedH))))))

    // 【核心修改】完美的中心膨胀动画
    transform: Translate {
        // 计算公式：(展开高度 - 折叠高度) / 2
        // 这里的计算结果是 (42 - 32) / 2 = 5px。
        // 向上移动 5px，同时高度增加 10px，视觉效果就是上下各扩展 5px。
        y: isLyricsMode ? -((lyricsH - collapsedH) / 2) : 0
        
        Behavior on y { 
            NumberAnimation { 
                duration: 500
                easing.type: Easing.OutBack
                // 使用 1.0 的回弹系数，让膨胀感清晰且有力
                easing.overshoot: 1.0 
            } 
        }
    }

    // 确保宽度、高度的动画曲线与位移完全一致，实现同步膨胀
    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
    Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
    Behavior on radius { NumberAnimation { duration: 500 } }

    // ================= IPC 监听 =================
    Process {
        id: ipcListener
        command: ["bash", "-c", "PIPE=/tmp/qs_launcher.pipe; if [ ! -p $PIPE ]; then rm -f $PIPE && mkfifo $PIPE; fi; while true; do cat $PIPE; done"]
        running: true 
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                if (data.indexOf("dashboard") !== -1) {
                    if (root.showDashboard) root.showDashboard = false;
                    else {
                        root.showLauncher = false; root.showWallpaper = false; root.expanded = false; root.showLyrics = false;
                        root.showDashboard = true; 
                    }
                }
                else if (data.indexOf("wallpaper") !== -1) {
                    if (root.showWallpaper) root.showWallpaper = false;
                    else {
                        root.showLauncher = false; root.showDashboard = false; root.expanded = false; root.showLyrics = false;
                        root.showWallpaper = true;
                    }
                }
                else if (data.indexOf("toggle") !== -1) {
                    root.showDashboard = false; root.showWallpaper = false;
                    if (root.showLauncher) root.showLauncher = false;
                    else { root.expanded = false; root.showLyrics = false; root.showLauncher = true; }
                }
            }
        }
        onExited: (code, status) => { restartTimer.start() }
    }
    Timer { id: restartTimer; interval: 100; onTriggered: ipcListener.running = true }

    // ================= 音频与通知服务 =================
    PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }
    property var audioNode: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    Timer { id: volHideTimer; interval: 2000; onTriggered: root.showVolume = false }
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
        
        // 【核心开关】
        // 利用 QML 的绑定特性：
        // 只要列表里有东西，它就是 true (开启)
        // 只要列表空了，它就是 false (关闭)
        // 这比任何 playerctl 命令都快，且零消耗
        running: Mpris.players.values.length > 0
        
        // 【自动清理】
        // 当 running 变成 false 时 (意味着所有播放器都关了)
        // 立即清空当前播放器，让灵动岛UI隐藏，防止残留
        onRunningChanged: {
            if (!running) root.currentPlayer = null
        }

        onTriggered: {
            var players = Mpris.players.values
            
            // 双重保险：虽然 running 保证了不为空，但防一手
            if (players.length === 0) {
                root.currentPlayer = null
                return
            }

            // A. 优先找正在播放的 (状态为 Playing)
            var playingPlayer = null
            for (let i = 0; i < players.length; i++) {
                if (players[i].isPlaying) { 
                    playingPlayer = players[i]
                    break
                }
            }

            if (playingPlayer) {
                // 如果找到了正在播放的，且和当前不一样，就更新
                if (root.currentPlayer !== playingPlayer) root.currentPlayer = playingPlayer
            } else {
                // B. 如果全员暂停 (兜底逻辑)
                // 先检查当前显示的播放器是不是还在列表里 (防止它刚被关掉)
                var currentIsValid = false
                if (root.currentPlayer) {
                    for (let i = 0; i < players.length; i++) {
                        if (players[i] === root.currentPlayer) {
                            currentIsValid = true
                            break
                        }
                    }
                }
                
                // 如果当前播放器失效了 (比如退出了)，就随便选列表里第一个顶替
                // 如果当前播放器还在 (只是暂停了)，就保持不变
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
                if (root.showDashboard) root.showDashboard = false;
                else if (root.showWallpaper) root.showWallpaper = false;
                else if (root.showLauncher) root.showLauncher = false;
                root.showLyrics = !root.showLyrics;
                if (root.showLyrics) root.expanded = false;
            } 
            else {
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
            opacity: (!root.expanded && !root.isNotifMode && !root.isVolumeMode && !root.isLauncherMode && !root.isWallpaperMode && !root.isDashboardMode && !root.isLyricsMode) ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        VolumeContent { 
            anchors.fill: parent; audioNode: root.audioNode; 
            opacity: root.isVolumeMode ? 1 : 0; visible: opacity > 0;
            Behavior on opacity { NumberAnimation { duration: 200 } } 
        }
        
        NotificationContent { 
            anchors.fill: parent; anchors.margins: 10; manager: notifManager; 
            opacity: root.isNotifMode ? 1 : 0; visible: opacity > 0;
            Behavior on opacity { NumberAnimation { duration: 200 } } 
        }
        
        LyricsContent {
            anchors.fill: parent
            player: root.currentPlayer
            active: root.isLyricsMode 
            opacity: root.isLyricsMode ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        
        MediaContent {
            anchors.fill: parent
            anchors.margins: 20
            player: root.expanded ? root.currentPlayer : null
            opacity: (root.expanded && !root.isLyricsMode) ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        
        LauncherContent { 
            anchors.fill: parent; onLaunchRequested: root.showLauncher = false; 
            opacity: root.isLauncherMode ? 1 : 0; visible: opacity > 0;
            Behavior on opacity { NumberAnimation { duration: 200 } } 
        }

        WallpaperContent {
            anchors.fill: parent
            onWallpaperChanged: root.showWallpaper = false
            opacity: root.isWallpaperMode ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        DashboardContent {
            anchors.fill: parent
            opacity: root.isDashboardMode ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
