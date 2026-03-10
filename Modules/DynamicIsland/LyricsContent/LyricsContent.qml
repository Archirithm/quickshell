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

    // ============================================================
    // 【动态自适应宽度引擎】
    // ============================================================
    property int defaultTextWidth: 350 // 默认保底宽度，短歌词会保持在这个宽度
    property int currentTextWidth: defaultTextWidth // 初始宽度
    
    // 暴露给外部的真实需要宽度：封面(26) + 左间距(15) + 缝隙(12) + 右间距(15) = 68
    implicitWidth: 68 + currentTextWidth 

    // ================= 1. 歌词获取逻辑 =================
    Process {
        id: lyricsFetcher
        command: ["python3", Quickshell.shellDir + "/scripts/lyrics_fetcher.py", root.trackTitle, root.trackArtist, root.playerName]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var json = JSON.parse(data)
                    if (json.length > 0) { 
                        root.lyricsModel = json; root.currentLineIndex = 0;
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
        id: debounceTimer; interval: 300; repeat: false; 
        onTriggered: {
            if (root.trackTitle !== "") { 
                root.lyricsModel = []; root.currentLineIndex = 0; 
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
                if (root.lyricsModel[i].time <= (currentSec + 0.5)) activeIdx = i; else break
            }
            
            // 解决前奏留白问题
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
            anchors.left: parent.left; anchors.leftMargin: 15; anchors.verticalCenter: parent.verticalCenter
            width: 26; height: 26
            
            Image {
                id: coverImg; anchors.fill: parent
                source: root.artUrl; visible: root.artUrl !== ""; fillMode: Image.PreserveAspectCrop
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: ShaderEffectSource {
                        sourceItem: Rectangle { width: coverImg.width; height: coverImg.height; radius: 5; color: "black" }
                    }
                }
            }
            Text {
                visible: root.artUrl === ""; anchors.centerIn: parent
                text: "\uf001"; font.family: "Symbols Nerd Font Mono"; font.pixelSize: 14; color: "#80ffffff"
            }
        }

        // 歌词列表 (纯粹的纵向滚动模式)
        ListView {
            id: lyricsView
            anchors.left: albumCoverContainer.right
            anchors.leftMargin: 12
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            
            // 宽度跟随当前歌词变化
            width: root.currentTextWidth
            
            interactive: false
            model: root.lyricsModel
            currentIndex: root.currentLineIndex
            
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: 0 
            highlightMoveDuration: 400 

            delegate: Item {
                width: ListView.view.width
                height: 42 
                property bool isCurrent: ListView.isCurrentItem

                // 【核心机制】：当这行歌词被激活时，测量宽度并与默认保底宽度对比
                onIsCurrentChanged: {
                    if (isCurrent) {
                        root.currentTextWidth = Math.max(root.defaultTextWidth, Math.min(lyricText.implicitWidth, 800))
                    }
                }

                Text {
                    id: lyricText
                    anchors.centerIn: parent
                    text: modelData.text
                    
                    color: "white"
                    
                    font.family: Sizes.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter 
                }
            }
        }
    }
}
