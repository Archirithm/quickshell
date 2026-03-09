import QtQuick
import QtQuick.Layouts
import QtQuick.Effects 
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.config 
import qs.Services 

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
    property int defaultTextWidth: 350 
    property int currentTextWidth: defaultTextWidth 
    
    // 左边距(15) + 封面(26) + 间距(12) + 歌词(动态) + 间距(12) + 频谱(22) + 右边距(15) = 102
    implicitWidth: 102 + currentTextWidth 

    Connections {
        target: root
        function onActiveChanged() {
            if (root.active) CavaService.refCount++;
            else CavaService.refCount = Math.max(0, CavaService.refCount - 1);
        }
    }

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

        // --- 专辑封面 ---
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
                    maskSource: ShaderEffectSource { sourceItem: Rectangle { width: coverImg.width; height: coverImg.height; radius: 5; color: "black" } }
                }
            }
            Text {
                visible: root.artUrl === ""; anchors.centerIn: parent
                text: "\uf001"; font.family: "Symbols Nerd Font Mono"; font.pixelSize: 14; color: "#80ffffff"
            }
        }

        // --- 歌词列表 ---
        ListView {
            id: lyricsView
            anchors.left: albumCoverContainer.right
            anchors.leftMargin: 12
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            
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

        // ============================================================
        // 【全新】：高动态对称聚合频谱条
        // ============================================================
        Item {
            id: spectrumContainer
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            width: 21  
            height: 16 

            property var smoothValues: [0, 0, 0, 0, 0, 0]

            Timer {
                interval: 16 
                running: root.active && CavaService.cavaAvailable
                repeat: true
                onTriggered: {
                    let s = spectrumContainer.smoothValues;
                    let r = CavaService.values;
                    if (!r || r.length < 30) return;
                    
                    // 核心1：频段聚合函数 (找出该区间的能量最大值，绝不遗漏)
                    let getRegionMax = (start, end) => {
                        let maxV = 0;
                        for (let i = start; i <= end; i++) {
                            if (r[i] > maxV) maxV = r[i];
                        }
                        return maxV;
                    };

                    let targets = [0, 0, 0, 0, 0, 0];
                    
                    // 核心2：对称式频率分布映射
                    // 柱 0, 5 (最外侧)：高频 (人声唇齿音、镲片)，高频能量天生弱，乘以 1.5 倍补偿
                    targets[0] = getRegionMax(16, 22) * 1.5;
                    targets[5] = getRegionMax(23, 29) * 1.5;
                    
                    // 柱 1, 4 (内侧)：中频 (吉他、主唱)，乘以 1.2 倍补偿
                    targets[1] = getRegionMax(6, 10) * 1.2;
                    targets[4] = getRegionMax(11, 15) * 1.2;
                    
                    // 柱 2, 3 (正中间)：重低频 (底鼓、贝斯)，音乐动力的心脏
                    targets[2] = getRegionMax(0, 2);
                    targets[3] = getRegionMax(3, 5);

                    // 核心3：提取全局重音节拍
                    let globalBeat = Math.max(targets[2], targets[3]);

                    for (let i = 0; i < 6; i++) {
                        // 核心4：混合共振引擎
                        // 自身频段占 80%，全局重低音占 20%。让即使没有高频的鼓点，也能带动旁边柱子微微颤动
                        let finalTarget = Math.min(100, targets[i] * 0.8 + globalBeat * 0.2);
                        
                        let diff = finalTarget - s[i];
                        
                        // 物理阻尼优化：攻击(Attack)极快，释放(Release)像果冻一样粘滞
                        if (diff > 0) s[i] += 0.85 * diff; // 爆发速度提升，完美卡点
                        else s[i] += 0.08 * diff;          // 下落拖影加长，增强顺滑感
                    }
                    
                    spectrumContainer.smoothValues = s;
                    spectrumCanvas.requestPaint();
                }
            }

            Canvas {
                id: spectrumCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    let s = parent.smoothValues;
                    
                    ctx.beginPath();
                    ctx.lineCap = "round"; 
                    ctx.lineWidth = 2.5;   
                    ctx.strokeStyle = String(Colorscheme.primary); 

                    for(let i = 0; i < 6; i++) {
                        let val = Math.min(1.0, s[i] / 100.0);
                        let h = Math.max(3, val * height); // 最低保持 3px 圆点
                        
                        let x = 1.25 + i * 3.7; 
                        
                        ctx.moveTo(x, height / 2 - h / 2);
                        ctx.lineTo(x, height / 2 + h / 2);
                    }
                    ctx.stroke();
                }
            }
        }
    }
}
