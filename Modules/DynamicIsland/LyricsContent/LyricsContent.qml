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
    
    // 保留这个变量，用于修复“收起灵动岛时不切歌”的 Bug
    property string currentLoadedTitle: ""

    // ================= 1. 歌词获取逻辑 (保持不变) =================
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
                    } 
                    else { root.lyricsModel = [{time: 0, text: "暂无歌词"}] }
                } catch (e) { root.lyricsModel = [{time: 0, text: "歌词错误"}] }
            }
        }
    }

    onTrackTitleChanged: triggerReload()
    // 展开灵动岛时，如果发现歌名不对，强制刷新 (保留此好评功能)
    onActiveChanged: { if (active && root.trackTitle !== root.currentLoadedTitle) triggerReload() }

    function triggerReload() {
        if (!root.active) return
        if (lyricsFetcher.running) lyricsFetcher.running = false
        debounceTimer.restart()
    }

    Timer { id: debounceTimer; interval: 300; repeat: false; onTriggered: {
        if (root.trackTitle !== "") { root.lyricsModel = []; root.currentLineIndex = 0; lyricsFetcher.running = true }
    }}

    // ================= 2. 极简同步逻辑 (已移除所有防抖/瞬移代码) =================
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

            // 只要索引变了，就直接赋值。
            // 没有任何复杂的 diff 判断，ListView 会自己决定怎么滚过去。
            if (activeIdx !== -1 && activeIdx !== root.currentLineIndex) {
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

        // 歌词列表
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
            
            // 回归最稳定的默认模式
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: 42 
            highlightMoveDuration: 400 

            delegate: Item {
                width: ListView.view.width
                height: 42 
                property bool isCurrent: ListView.isCurrentItem

                Text {
                    anchors.centerIn: parent
                    text: modelData.text
                    color: isCurrent ? "white" : "transparent"
                    font.pixelSize: 14; font.bold: true
                    elide: Text.ElideRight; width: parent.width; horizontalAlignment: Text.AlignHCenter 
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }
}
