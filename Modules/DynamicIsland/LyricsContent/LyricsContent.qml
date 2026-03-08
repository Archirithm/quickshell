import QtQuick
import QtQuick.Layouts
import QtQuick.Effects 
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.config 

Item {
    id: root
    
    required property var player
    property bool active: false
    property var lyricsModel: []
    property int currentLineIndex: 0
    
    readonly property string trackTitle: player ? player.trackTitle : ""
    readonly property string trackArtist: player ? player.trackArtist : ""
    readonly property string playerName: player ? (player.identity || player.busName || "") : ""
    readonly property string artUrl: player ? (player.trackArtUrl || "") : ""
    
    property string currentLoadedTitle: ""

    // ================= 1. 歌词获取逻辑 =================
    Process {
        id: lyricsFetcher
        command: ["python3", Quickshell.shellDir + "/scripts/lyrics_fetcher.py", root.trackTitle, root.trackArtist, root.playerName]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var json = JSON.parse(data)
                    if (json.length > 0) { 
                        root.lyricsModel = json;
                        root.currentLineIndex = 0;
                        root.currentLoadedTitle = root.trackTitle
                    } else { 
                        root.lyricsModel = [{time: 0, text: "暂无歌词"}] 
                    }
                } catch (e) { root.lyricsModel = [{time: 0, text: "歌词错误"}] }
            }
        }
    }

    onTrackTitleChanged: triggerReload()
    onActiveChanged: { if (active && root.trackTitle !== root.currentLoadedTitle) triggerReload() }

    function triggerReload() {
        if (!root.active) return
        if (lyricsFetcher.running) lyricsFetcher.running = false
        debounceTimer.restart()
    }

    Timer { 
        id: debounceTimer;
        interval: 300; repeat: false; 
        onTriggered: {
            if (root.trackTitle !== "") { 
                root.lyricsModel = [];
                root.currentLineIndex = 0; 
                lyricsFetcher.running = true 
            }
        }
    }

    // ================= 2. 极简同步逻辑 =================
    Timer {
        interval: 100
        running: root.active && root.lyricsModel.length > 1 && root.player
        repeat: true
        onTriggered: {
            if (!root.player) return

            var rawPos = root.player.position
            var currentSec = (rawPos > 100000) ? (rawPos / 1000000) : rawPos
            
            var activeIdx = -1
            for (var i = 0; i < root.lyricsModel.length; i++) {
                if (root.lyricsModel[i].time <= (currentSec + 0.5)) activeIdx = i;
                else break
            }
            
            // 解决前奏留白问题：如果音乐刚开始还没到第一句，强制对齐第 0 句（即前奏占位符）
            if (activeIdx === -1) activeIdx = 0

            if (activeIdx !== root.currentLineIndex) {
                root.currentLineIndex = activeIdx
            }
        }
    }

    // ================= 3. 界面层 =================
    Item {
        anchors.fill: parent
        clip: true 

        // 专辑封面
        Item {
            id: albumCoverContainer
            anchors.left: parent.left;
            anchors.leftMargin: 15; anchors.verticalCenter: parent.verticalCenter
            width: 26; height: 26
            
            Image {
                id: coverImg;
                anchors.fill: parent
                source: root.artUrl;
                visible: root.artUrl !== ""; fillMode: Image.PreserveAspectCrop
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: ShaderEffectSource {
                        sourceItem: Rectangle { width: coverImg.width; height: coverImg.height; radius: 5; color: "black" }
                    }
                }
            }
            Text {
                visible: root.artUrl === "";
                anchors.centerIn: parent
                text: "\uf001";
                font.family: "Symbols Nerd Font Mono"; font.pixelSize: 14; color: "#80ffffff"
            }
        }

        // 歌词列表 (灵动岛单行呼吸模式)
        ListView {
            id: lyricsView
            anchors.left: albumCoverContainer.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            
            interactive: false
            model: root.lyricsModel
            currentIndex: root.currentLineIndex
            
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: 42 
            // 稍微调快了一点滚动速度，让单行切词更加干脆
            highlightMoveDuration: 300 

            delegate: Item {
                width: ListView.view.width
                height: 42 
                property bool isCurrent: ListView.isCurrentItem

                Text {
                    anchors.centerIn: parent
                    text: modelData.text
                    // 【高级质感强化】：当前行纯白显示，非当前行变成完全透明且带有缩放，形成呼吸感
                    color: isCurrent ? "white" : "#00ffffff"
                    font.pixelSize: isCurrent ? 14 : 12
                    font.bold: true
                    opacity: isCurrent ? 1.0 : 0.0
                    scale: isCurrent ? 1.0 : 0.95
                    
                    elide: Text.ElideRight;
                    width: parent.width; horizontalAlignment: Text.AlignHCenter 
                    transformOrigin: Item.Center
                    
                    // 使用 OutQuart 缓动曲线，让消失和浮现极度顺滑
                    Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutQuart } }
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                    Behavior on font.pixelSize { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
                }
            }
        }
    }
}
