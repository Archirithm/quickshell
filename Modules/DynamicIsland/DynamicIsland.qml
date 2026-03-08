import QtQuick
import Quickshell
import Quickshell.Io  
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.Services
import qs.config

import qs.Modules.DynamicIsland.ClockContent
import qs.Modules.DynamicIsland.MediaContent  
import qs.Modules.DynamicIsland.Media         
import qs.Modules.DynamicIsland.NotificationContent
import qs.Modules.DynamicIsland.VolumeContent
import qs.Modules.DynamicIsland.LauncherContent
import qs.Modules.DynamicIsland.WallpaperContent
import qs.Modules.DynamicIsland.DashboardContent
import qs.Modules.DynamicIsland.LyricsContent 
import qs.Modules.DynamicIsland.OverviewContent 
import qs.Modules.DynamicIsland.WeatherContent // <-- 新增：引入天气模块

Rectangle {
    id: root

    // ================= 状态定义 =================
    property bool showDashboard: false
    property bool showMedia: false       
    property bool showWallpaper: false
    property bool showLauncher: false
    property bool showOverview: false 
    property bool showLyrics: false 
    property bool showWeather: false // <-- 新增：天气状态
    property bool expanded: false
    property bool showVolume: false

    // ================= 互斥模式判定 =================
    property bool isDashboardMode: showDashboard
    
    property bool isMediaMode: showMedia && !showDashboard
                               
    property bool isWallpaperMode: showWallpaper && !showMedia && !showDashboard
               
    property bool isLyricsMode: showLyrics && !showWallpaper && !showMedia && !showDashboard
                                
    property bool isLauncherMode: showLauncher && !isLyricsMode && !showWallpaper && !showMedia && !showDashboard
                    
    property bool isOverviewMode: showOverview && !showLauncher && !isLyricsMode && !showWallpaper && !showMedia && !showDashboard

    // <-- 新增：天气模式互斥层级（放在 Overview 之后）
    property bool isWeatherMode: showWeather && !isOverviewMode && !showLauncher && !isLyricsMode && !showWallpaper && !showMedia && !showDashboard
                                  
    // <-- 更新：音量和通知模式需排除天气模式
    property bool isVolumeMode: showVolume && !expanded && !isWeatherMode && !isOverviewMode && !showLauncher && !isLyricsMode && !showWallpaper && !showMedia && !showDashboard
              
    property bool isNotifMode: notifManager.hasNotifs && !expanded && !showVolume && !isWeatherMode && !isOverviewMode && !showLauncher && !isLyricsMode && !showWallpaper && !showMedia && !showDashboard

    // ================= 尺寸定义 =================
    property int dashW: 810; property int dashH: 420
    property int mediaW: 720; property int mediaH: 480
    property int wallW: 810; property int wallH: 180
    property int launchW: 400; property int launchH: 420 
    property int overviewW: 720; property int overviewH: 360 
    property int weatherW: 720; property int weatherH: 540 // <-- 新增：天气面板尺寸
    property int lyricsW: 480; property int lyricsH: 42 
    property int expandedW: 420; property int expandedH: 180
    property int collapsedW: 220; property int collapsedH: 32
    property int notifW: 380; property int notifH: (notifManager.model.count * 70) + 20
    property int volW: 220; property int volH: 40
    
    // ================= 视觉与基础属性 =================
    color: Colorscheme.background
    clip: true
    z: 100
  
    // <-- 更新：将 isWeatherMode 加入圆角判定
    radius: (expanded || isNotifMode || isVolumeMode || isLauncherMode || 
             isWallpaperMode || isDashboardMode || isLyricsMode ||
             isOverviewMode || isMediaMode || isWeatherMode) 
             ? 24 : height / 2

    // <-- 更新：动态宽度加入天气判定
    width: isDashboardMode ? dashW : 
           isMediaMode     ? mediaW : 
           isWallpaperMode ? wallW : 
           isOverviewMode  ? overviewW : 
           isWeatherMode   ? weatherW : 
           isLyricsMode    ? lyricsW : 
           isLauncherMode  ? launchW : 
           expanded        ? expandedW : 
           isVolumeMode    ? volW : 
           isNotifMode     ? notifW : collapsedW

    // <-- 更新：动态高度加入天气判定
    height: isDashboardMode ? dashH : 
            isMediaMode     ? mediaH : 
            isWallpaperMode ? wallH : 
            isOverviewMode  ? overviewH : 
            isWeatherMode   ? weatherH : 
            isLyricsMode    ? lyricsH : 
            isLauncherMode  ? launchH : 
            expanded        ? expandedH : 
            isVolumeMode    ? volH : 
            isNotifMode     ? notifH : collapsedH

    transform: Translate {
        y: isLyricsMode ? -((lyricsH - collapsedH) / 2) : 0
        Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
    }

    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
    Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
    Behavior on radius { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

    // ================= IPC 通信处理 =================
    IpcHandler {
        target: "island"
        
        function dashboard() {
            if (root.showDashboard) { root.showDashboard = false; return "DASHBOARD_CLOSED" } 
            else { 
                root.showLauncher = false; root.showOverview = false; root.showWallpaper = false; 
                root.showMedia = false; root.showWeather = false; root.expanded = false; root.showLyrics = false;
                root.showDashboard = true
                return "DASHBOARD_OPENED" 
            }
        }
        
        function media() {
            root.showDashboard = false; root.showWallpaper = false; root.showLauncher = false; root.showOverview = false; root.showWeather = false;
            if (root.showMedia) { root.showMedia = false; return "MEDIA_CLOSED" } 
            else { root.expanded = false; root.showLyrics = false; root.showMedia = true; return "MEDIA_OPENED" }
        }
        
        function wallpaper() {
            if (root.showWallpaper) { root.showWallpaper = false; return "WALLPAPER_CLOSED" } 
            else { 
                root.showLauncher = false; root.showOverview = false; root.showMedia = false; root.showDashboard = false;
                root.showWeather = false; root.expanded = false; root.showLyrics = false;
                root.showWallpaper = true
                return "WALLPAPER_OPENED" 
            }
        }
 
        function launcher() {
            root.showDashboard = false; root.showMedia = false; root.showWallpaper = false; root.showOverview = false; root.showWeather = false;
            if (root.showLauncher) { root.showLauncher = false; return "LAUNCHER_CLOSED" } 
            else { root.expanded = false; root.showLyrics = false; root.showLauncher = true; return "LAUNCHER_OPENED" }
        }
        
        function overview() {
            root.showDashboard = false; root.showMedia = false; root.showWallpaper = false; root.showLauncher = false; root.showWeather = false;
            if (root.showOverview) { root.showOverview = false; return "OVERVIEW_CLOSED" } 
            else { root.expanded = false; root.showLyrics = false; root.showOverview = true; return "OVERVIEW_OPENED" }
        }

        // <-- 新增：天气的 IPC 呼出处理
        function weather() {
            root.showDashboard = false; root.showMedia = false; root.showWallpaper = false; 
            root.showLauncher = false; root.showOverview = false;
            if (root.showWeather) { root.showWeather = false; return "WEATHER_CLOSED" }
            else { root.expanded = false; root.showLyrics = false; root.showWeather = true; return "WEATHER_OPENED" }
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
        // <-- 更新：在其他面板打开时阻止音量 OSD 弹出
        if (root.showDashboard || root.showMedia || root.showOverview || root.showLauncher || root.showWallpaper || root.showWeather || root.expanded || root.showLyrics) return
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
                else if (root.showMedia) root.showMedia = false
                else if (root.showWallpaper) root.showWallpaper = false 
                else if (root.showLauncher) root.showLauncher = false
                else if (root.showOverview) root.showOverview = false 
                else if (root.showWeather) root.showWeather = false // <-- 新增
                
                root.showLyrics = !root.showLyrics
                if (root.showLyrics) root.expanded = false
            } else {
                if (root.showDashboard) root.showDashboard = false
                else if (root.showMedia) root.showMedia = false
                else if (root.showWallpaper) root.showWallpaper = false 
                else if (root.showLyrics) root.showLyrics = false 
                else if (root.showLauncher) root.showLauncher = false
                else if (root.showOverview) root.showOverview = false 
                else if (root.showWeather) root.showWeather = false // <-- 新增
                else root.expanded = !root.expanded
            }
        }
    }

    // ================= 内部组件挂载区 =================
    Item {
        anchors.fill: parent
        
        ClockContent { 
            anchors.fill: parent; player: root.currentPlayer
            opacity: (!root.expanded && !root.isNotifMode && !root.isVolumeMode && !root.isLauncherMode && !root.isWallpaperMode && !root.isDashboardMode && !root.isLyricsMode && !root.isOverviewMode && !root.isMediaMode && !root.isWeatherMode) ? 1 : 0
            visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } 
        }
            
        VolumeContent { 
            anchors.fill: parent; audioNode: root.audioNode
            opacity: root.isVolumeMode ? 1 : 0
            visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } 
        }
            
        NotificationContent { 
            anchors.fill: parent; anchors.margins: 10; manager: notifManager
            opacity: root.isNotifMode ? 1 : 0
            visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } 
        }
            
        LyricsContent { 
            anchors.fill: parent; player: root.currentPlayer; active: root.isLyricsMode
            opacity: root.isLyricsMode ? 1 : 0
            visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } 
        }
        
        MediaContent { 
            anchors.fill: parent; anchors.margins: 20
            player: root.expanded ? root.currentPlayer : null
            opacity: (root.expanded && !root.isLyricsMode && !root.isMediaMode) ? 1 : 0
            visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } 
        }

        Media { 
            anchors.fill: parent
            player: root.currentPlayer
            opacity: root.isMediaMode ? 1 : 0
            visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } 
        }
            
        LauncherContent { 
            anchors.fill: parent; onLaunchRequested: root.showLauncher = false
            opacity: root.isLauncherMode ? 1 : 0
            visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } 
        }
            
        WallpaperContent { 
            anchors.fill: parent; onWallpaperChanged: root.showWallpaper = false
            opacity: root.isWallpaperMode ? 1 : 0
            visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } 
        }
            
        DashboardContent { 
            anchors.fill: parent
            opacity: root.isDashboardMode ? 1 : 0
            visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } 
        }
            
        OverviewContent { 
            anchors.fill: parent; onCloseRequested: root.showOverview = false
            opacity: root.isOverviewMode ? 1 : 0
            visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 200 } } 
        }

        // <-- 新增：挂载天气组件
        WeatherContent {
            anchors.fill: parent
            opacity: root.isWeatherMode ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
