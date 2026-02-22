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

    property bool isDashboardMode: showDashboard
    property bool isWallpaperMode: showWallpaper && !showDashboard
    property bool isLyricsMode: showLyrics && !showDashboard && !showWallpaper
    property bool isLauncherMode: showLauncher && !showWallpaper && !showDashboard && !isLyricsMode
    property bool isVolumeMode: showVolume && !expanded && !showLauncher && !showWallpaper && !showDashboard && !isLyricsMode
    property bool isNotifMode: notifManager.hasNotifs && !expanded && !showVolume && !showLauncher && !showWallpaper && !showDashboard && !isLyricsMode

    // ================= 尺寸定义 =================
    property int dashW: 810
    property int dashH: 420
    
    property int wallW: 810
    property int wallH: 180
    property int launchW: 400
    property int launchH: 420 
    property int lyricsW: 480
    property int lyricsH: 42 
    property int expandedW: 420
    property int expandedH: 180
    property int collapsedW: 220
    property int collapsedH: 32
    property int notifW: 380
    property int notifH: (notifManager.model.count * 70) + 20
    property int volW: 220
    property int volH: 40
    
    color: Colorscheme.background
    clip: true
    z: 100
    
    radius: (expanded || isNotifMode || isVolumeMode || isLauncherMode || isWallpaperMode || isDashboardMode || isLyricsMode) ?
    24 : height / 2

    width: isDashboardMode ?
    dashW : (isWallpaperMode ? wallW : (isLyricsMode ? lyricsW : (isLauncherMode ? launchW : (expanded ? expandedW : (isVolumeMode ? volW : (isNotifMode ? notifW : collapsedW))))))
    height: isDashboardMode ?
    dashH : (isWallpaperMode ? wallH : (isLyricsMode ? lyricsH : (isLauncherMode ? launchH : (expanded ? expandedH : (isVolumeMode ? volH : (isNotifMode ? notifH : collapsedH))))))


    transform: Translate {
        y: isLyricsMode ? -((lyricsH - collapsedH) / 2) : 0
        Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
    }

    // 将所有的形变动画强制统一为 500ms 的 OutBack 弹簧动画
    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
    Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
    Behavior on radius { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

    IpcHandler {
        target: "island"
        function dashboard() {
            if (root.showDashboard) { root.showDashboard = false; return "DASHBOARD_CLOSED" }
            else { root.showLauncher = false; root.showWallpaper = false; root.expanded = false; root.showLyrics = false; root.showDashboard = true; return "DASHBOARD_OPENED" }
        }
        function wallpaper() {
            if (root.showWallpaper) { root.showWallpaper = false; return "WALLPAPER_CLOSED" }
            else { root.showLauncher = false; root.showDashboard = false; root.expanded = false; root.showLyrics = false; root.showWallpaper = true; return "WALLPAPER_OPENED" }
        }
        function launcher() {
            root.showDashboard = false; root.showWallpaper = false;
            if (root.showLauncher) { root.showLauncher = false; return "LAUNCHER_CLOSED" }
            else { root.expanded = false; root.showLyrics = false; root.showLauncher = true; return "LAUNCHER_OPENED" }
        }
    }

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
        root.showVolume = true; volHideTimer.restart();
    }

    NotificationManager { id: notifManager }
    
    property var currentPlayer: null

    Timer {
        id: stickyTimer; interval: 500; repeat: true; triggeredOnStart: true; running: Mpris.players.values.length > 0
        onRunningChanged: { if (!running) root.currentPlayer = null }
        onTriggered: {
            var players = Mpris.players.values; if (players.length === 0) { root.currentPlayer = null; return }
            var playingPlayer = null
            for (let i = 0; i < players.length; i++) { if (players[i].isPlaying) { playingPlayer = players[i]; break } }
            if (playingPlayer) { if (root.currentPlayer !== playingPlayer) root.currentPlayer = playingPlayer }
            else {
                var currentIsValid = false
                if (root.currentPlayer) { for (let i = 0; i < players.length; i++) { if (players[i] === root.currentPlayer) { currentIsValid = true; break } } }
                if (!currentIsValid) root.currentPlayer = players[0]
            }
        }
    }

    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !isNotifMode && !isVolumeMode; acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                if (root.showDashboard) root.showDashboard = false; else if (root.showWallpaper) root.showWallpaper = false; else if (root.showLauncher) root.showLauncher = false;
                root.showLyrics = !root.showLyrics; if (root.showLyrics) root.expanded = false;
            } else {
                if (root.showDashboard) root.showDashboard = false; else if (root.showWallpaper) root.showWallpaper = false; else if (root.showLyrics) root.showLyrics = false; else if (root.showLauncher) root.showLauncher = false; else root.expanded = !root.expanded;
            }
        }
    }

    Item {
        anchors.fill: parent
        ClockContent { anchors.fill: parent; player: root.currentPlayer; opacity: (!root.expanded && !root.isNotifMode && !root.isVolumeMode && !root.isLauncherMode && !root.isWallpaperMode && !root.isDashboardMode && !root.isLyricsMode) ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } }
        VolumeContent { anchors.fill: parent; audioNode: root.audioNode; opacity: root.isVolumeMode ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } }
        NotificationContent { anchors.fill: parent; anchors.margins: 10; manager: notifManager; opacity: root.isNotifMode ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } }
        LyricsContent { anchors.fill: parent; player: root.currentPlayer; active: root.isLyricsMode; opacity: root.isLyricsMode ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } }
        MediaContent { anchors.fill: parent; anchors.margins: 20; player: root.expanded ? root.currentPlayer : null; opacity: (root.expanded && !root.isLyricsMode) ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } }
        LauncherContent { anchors.fill: parent; onLaunchRequested: root.showLauncher = false; opacity: root.isLauncherMode ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } }
        WallpaperContent { anchors.fill: parent; onWallpaperChanged: root.showWallpaper = false; opacity: root.isWallpaperMode ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } }
        DashboardContent { anchors.fill: parent; opacity: root.isDashboardMode ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } }
    }
}
