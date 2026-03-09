import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.config
import qs.Services

Item {
    id: root
    
    implicitWidth: 720
    implicitHeight: 480
    
    required property var player
    
    property string artUrl: (player && player.trackArtUrl) ? player.trackArtUrl : ""
    property string title: (player && player.trackTitle) ? player.trackTitle : "Not Playing"
    property string artist: (player && player.trackArtist) ? player.trackArtist : "Unknown Artist"
    property string album: (player && player.trackAlbum) ? player.trackAlbum : ""

    readonly property bool isActive: root.visible && root.player
    property bool showLyrics: false 

    property bool _isReady: false
    Component.onCompleted: _isReady = true

    // ==========================================
    // 歌词抓取与解析引擎 (路径已更新)
    // ==========================================
    ListModel { id: lyricsModel }
    
    Process {
        id: lyricsProc
        running: false
        // 【已修改】：指向 scripts 目录
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/lyrics_fetcher.py", root.title, root.artist]
        
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.trim() === "") return;
                try {
                    let parsed = JSON.parse(data);
                    lyricsModel.clear();
                    for(let i = 0; i < parsed.length; i++) {
                        lyricsModel.append({"time": parsed[i].time, "text": parsed[i].text});
                    }
                    lyricsList.currentIndex = 0;
                } catch(e) {}
            }
        }
    }

    Connections {
        target: root
        function onTitleChanged() {
            if (root.title && root.title !== "Not Playing") {
                lyricsModel.clear();
                lyricsModel.append({"time": 0, "text": "🎵 正在搜寻歌词..."});
                lyricsProc.running = false;
                lyricsProc.running = true;
            }
        }
    }

    // ==========================================
    // 封面主色调提取引擎
    // ==========================================
    Canvas {
        id: colorExtractor
        width: 1; height: 1; visible: false
        property color extractedColor: Colorscheme.primary

        Connections {
            target: root
            function onArtUrlChanged() {
                if (root.artUrl !== "") colorExtractor.loadImage(root.artUrl);
                else colorExtractor.extractedColor = Colorscheme.primary;
            }
        }
        onImageLoaded: {
            var ctx = getContext("2d");
            ctx.drawImage(root.artUrl, 0, 0, 1, 1);
            var imgData = ctx.getImageData(0, 0, 1, 1).data;
            
            var r = imgData[0] / 255.0;
            var g = imgData[1] / 255.0;
            var b = imgData[2] / 255.0;
            
            // 1. 将平均 RGB 转换为 HSL (色相、饱和度、亮度)
            var baseColor = Qt.rgba(r, g, b, 1.0);
            var h = baseColor.hslHue;
            var s = baseColor.hslSaturation;
            var l = baseColor.hslLightness;
            
            // 2. 钳制与放大 (去除泥巴色的核心魔法)
            // 放大 1.5 倍饱和度，让颜色变得更纯粹、更鲜艳
            s = Math.min(1.0, s * 1.5); 
            
            if (s < 0.1) {
                // 如果封面几乎是纯黑白灰 (饱和度极低)，强行提亮会变成难看的灰色
                // 这种情况我们直接回退到你系统的主题色，保证界面的绝对美观
                extractedColor = Colorscheme.primary; 
            } else {
                // 锁定最低亮度为 0.65 (65%)，最高 0.85 (85%)
                // 这样不管原图的平均色有多黑，最后算出来的颜色都自带“霓虹发光”感，绝对看得清！
                l = Math.max(0.65, Math.min(0.85, l)); 
                extractedColor = Qt.hsla(h, s, l, 1.0);
            }
        }
    }

    property color dynamicThemeColor: colorExtractor.extractedColor
    Behavior on dynamicThemeColor { ColorAnimation { duration: 800; easing.type: Easing.OutQuint } }

    // ==========================================
    // 进度与时间高频同步逻辑
    // ==========================================
    Connections {
        target: root
        function onIsActiveChanged() {
            if (root.isActive) CavaService.refCount++;
            else CavaService.refCount = Math.max(0, CavaService.refCount - 1);
        }
    }
    
    property double currentPos: 0
    Timer {
        interval: 100
        running: root.isActive
        repeat: true
        onTriggered: {
            if (root.player && !seekMa.pressed) {
                root.currentPos = root.player.position;
                
                if (root.showLyrics && lyricsModel.count > 0) {
                    let pos = root.currentPos;
                    let newIdx = 0;
                    for (let i = 0; i < lyricsModel.count; i++) {
                        if (lyricsModel.get(i).time <= pos) newIdx = i;
                        else break;
                    }
                    if (lyricsList.currentIndex !== newIdx) {
                        lyricsList.currentIndex = newIdx;
                    }
                }
            }
        }
    }

    function formatTime(val) {
        let num = Number(val);
        if (isNaN(num) || num <= 0) return "0:00";
        let seconds = (num > 100000) ? Math.floor(num / (num > 100000000 ? 1000000 : 1000)) : Math.floor(num);
        let m = Math.floor(seconds / 60);
        let s = seconds % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
    property double realProgress: (player && player.length > 0) ? (currentPos / player.length) : 0

    // ==========================================
    // 界面渲染层
    // ==========================================
    Rectangle {
        id: mainBg
        anchors.fill: parent
        
        // 【修改 1】：增加外边距，特别是底部留白，不让它紧贴 hub 底边
        anchors.topMargin: 5
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        anchors.bottomMargin: 25 
        
        // 【修改 2】：增大圆角让它看起来更现代
        radius: 24 
        color: Colorscheme.surface_container_low

        // 【核心修复】：废弃 clip: true，改用图层遮罩！
        // 只有使用 OpacityMask，内部的封面图和模糊层才会被完美限制在圆角内
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: mainBg.width
                height: mainBg.height
                radius: mainBg.radius
            }
        }

        Image {
            id: bgSource; source: root.artUrl
            anchors.fill: parent; fillMode: Image.PreserveAspectCrop; visible: false 
        }
        FastBlur { anchors.fill: parent; source: bgSource; radius: 64; visible: root.artUrl !== "" }
        Rectangle { anchors.fill: parent; color: "#B3000000" }

        Rectangle {
            id: lyricsToggleBtn
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 16
            width: 36; height: 36; radius: 18
            color: root.showLyrics ? root.dynamicThemeColor : "transparent"
            border.color: root.showLyrics ? "transparent" : "#44FFFFFF"
            z: 10 
            
            Text {
                anchors.centerIn: parent
                text: "lyrics" 
                font.family: "Material Symbols Outlined"
                font.pixelSize: 18
                color: root.showLyrics ? Colorscheme.background : "white"
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.showLyrics = !root.showLyrics }
        }

        // --- 主体布局分离 (状态机驱动) ---
        Item {
            id: stage
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: bottomControlPanel.top
            anchors.margins: 16

            state: root.showLyrics ? "LYRICS_OPEN" : "LYRICS_CLOSED"

            states: [
                State {
                    name: "LYRICS_CLOSED"
                    PropertyChanges { target: coverContainer; x: (stage.width - coverContainer.width) / 2; scale: 1.0 }
                    PropertyChanges { target: infoContainer; opacity: 1; visible: true }
                    PropertyChanges { target: lyricsContainer; x: stage.width + 50; opacity: 0; visible: false }
                },
                State {
                    name: "LYRICS_OPEN"
                    PropertyChanges { target: coverContainer; x: 40; scale: 0.9 }
                    PropertyChanges { target: infoContainer; opacity: 0; visible: false }
                    PropertyChanges { target: lyricsContainer; x: 280; opacity: 1; visible: true }
                }
            ]

            transitions: [
                Transition {
                    ParallelAnimation {
                        NumberAnimation { targets: [coverContainer, lyricsContainer]; properties: "x,scale"; duration: 600; easing.type: Easing.OutExpo }
                        NumberAnimation { targets: [infoContainer, lyricsContainer]; properties: "opacity"; duration: 400; easing.type: Easing.InOutQuad }
                    }
                }
            ]

            // 1. Cava 环形频谱 + 专辑封面
            Item {
                id: coverContainer
                width: 220; height: 220
                y: 10 
                
                property var smoothValues: new Array(30).fill(0)
                property real dynamicRotation: 90 

                Timer {
                    interval: 16 
                    running: root.isActive && CavaService.cavaAvailable
                    repeat: true
                    onTriggered: {
                        let s = parent.smoothValues;
                        let r = CavaService.values;
                        parent.dynamicRotation += 0.3; 
                        for (let i = 0; i < 30; i++) {
                            let diff = r[i] - s[i];
                            if (diff > 0) s[i] += 0.75 * diff; 
                            else if (diff < 0) s[i] += 0.12 * diff; 
                        }
                        parent.smoothValues = s;
                        spectrumCanvas.rotation = parent.dynamicRotation;
                        spectrumCanvas.requestPaint(); 
                    }
                }

                Canvas {
                    id: spectrumCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        let cx = width / 2; let cy = height / 2;
                        let baseRadius = 72; let maxAmp = 25; 
                        let s = parent.smoothValues;
                        let totalBars = 60;   
                        let angleStep = (Math.PI * 2) / totalBars;

                        ctx.beginPath();
                        ctx.lineCap = "round";       
                        ctx.strokeStyle = String(root.dynamicThemeColor); 

                        for (let i = 0; i < totalBars; i++) {
                            let dataIndex = (i < 30) ? i : (59 - i);
                            let val = Math.min(1.2, s[dataIndex] / 100.0); 
                            let amp = Math.max(0.01, val) * maxAmp;
                            let angle = i * angleStep;
                            let rInner = baseRadius - (amp * 0.05); 
                            let rOuter = baseRadius + (amp * 0.95); 

                            ctx.lineWidth = 2 + (val * 3);
                            ctx.moveTo(cx + Math.cos(angle) * rInner, cy + Math.sin(angle) * rInner);
                            ctx.lineTo(cx + Math.cos(angle) * rOuter, cy + Math.sin(angle) * rOuter);
                        }
                        ctx.stroke(); 
                    }
                }

                Rectangle {
                    width: 120; height: 120; radius: 60; color: "transparent"; anchors.centerIn: parent
                    Image {
                        id: artImg; anchors.fill: parent; source: root.artUrl !== "" ? root.artUrl : ""
                        fillMode: Image.PreserveAspectCrop; layer.enabled: true
                        layer.effect: OpacityMask { maskSource: Rectangle { width: artImg.width; height: artImg.height; radius: width / 2 } }
                    }
                    Text { anchors.centerIn: parent; text: "🎵"; font.pixelSize: 40; visible: root.artUrl === "" }
                }
            }

            // 2. 文本信息组
            ColumnLayout {
                id: infoContainer
                width: parent.width
                x: 0
                y: coverContainer.y + coverContainer.height + 16
                spacing: 2 

                Text { text: root.title; color: "white"; font.pixelSize: 20; font.bold: true; Layout.alignment: Qt.AlignHCenter; elide: Text.ElideRight; Layout.maximumWidth: root.width - 80 }
                Text { text: root.artist; color: "#cccccc"; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter; elide: Text.ElideRight; Layout.maximumWidth: root.width - 80 }
                Text { text: root.album; color: "#888888"; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter; elide: Text.ElideRight; Layout.maximumWidth: root.width - 80 }
            }

            // 3. 3D 悬浮歌词面板 (GPU 硬件加速版)
            Item {
                id: lyricsContainer
                width: stage.width - 280
                height: 240
                y: 10
                
                transform: Rotation {
                    origin.x: 0 
                    origin.y: lyricsContainer.height / 2
                    axis { x: 0; y: 1; z: 0 } 
                    angle: -30 
                }

                ListView {
                    id: lyricsList
                    anchors.fill: parent
                    model: lyricsModel
                    clip: true
                    
                    // 【核心优化 1】：加大间距，给 GPU 的缩放腾出物理空间，防止重叠
                    spacing: 24 
                    
                    preferredHighlightBegin: height / 2 - 30
                    preferredHighlightEnd: height / 2 + 30
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    interactive: false 
                    
                    highlightMoveDuration: 600
                    highlightMoveVelocity: -1

                    delegate: Text {
                        width: ListView.view.width
                        text: model.text
                        color: ListView.isCurrentItem ? "white" : "#99ffffff"
                        
                        // 【核心优化 2】：锁死基础字号，彻底禁止排版引擎重绘！
                        font.pixelSize: 18
                        font.bold: true 
                        opacity: ListView.isCurrentItem ? 1.0 : 0.5
                        
                        // 【核心优化 3】：开启 GPU 原生硬件缩放
                        transformOrigin: Item.Left
                        scale: ListView.isCurrentItem ? 1.25 : 1.0
                        
                        horizontalAlignment: Text.AlignLeft
                        wrapMode: Text.WordWrap
                        
                        // 使用极具高级感的四次方缓动曲线，顺滑到起飞
                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
                        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutQuart } }
                        Behavior on color { ColorAnimation { duration: 500; easing.type: Easing.OutQuart } }
                    }
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: LinearGradient {
                        width: lyricsContainer.width
                        height: lyricsContainer.height
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" } 
                            GradientStop { position: 0.25; color: "black" }      
                            GradientStop { position: 0.75; color: "black" }      
                            GradientStop { position: 1.0; color: "transparent" } 
                        }
                    }
                }
            }
        }

        // --- 下半部分 (进度条和控制按钮) ---
        ColumnLayout {
            id: bottomControlPanel
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 6

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 340 
                Layout.preferredHeight: 46 

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    Item {
                        id: waveContainer
                        Layout.fillWidth: true; Layout.preferredHeight: 26

                        Rectangle {
                            anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            height: 2; color: root.dynamicThemeColor; opacity: 0.2 
                        }

                        Item {
                            id: progressClip
                            height: parent.height
                            width: seekMa.pressed ? Math.max(0, Math.min(seekMa.mouseX, waveContainer.width)) : (root.realProgress * waveContainer.width)
                            clip: true
                            Behavior on width { enabled: root.visible && !seekMa.pressed; SmoothedAnimation { velocity: 200; duration: 1500; reversingMode: SmoothedAnimation.Sync } }

                            Canvas {
                                id: fgWave
                                width: waveContainer.width; height: waveContainer.height
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height); ctx.beginPath(); ctx.lineWidth = 2.5;
                                    ctx.strokeStyle = String(root.dynamicThemeColor); 
                                    let freq = 0.15, amp = 4;
                                    for (let x = 0; x < width; x++) { let y = height / 2 + Math.sin(x * freq) * amp; if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y); }
                                    ctx.stroke();
                                }
                                Connections { target: waveContainer; function onWidthChanged() { fgWave.requestPaint() } }
                                Connections { target: root; function onDynamicThemeColorChanged() { fgWave.requestPaint() } }
                            }
                        }

                        Rectangle {
                            width: 4; height: 18; radius: 2; color: root.dynamicThemeColor 
                            x: progressClip.width - 2; anchors.verticalCenter: parent.verticalCenter
                        }

                        MouseArea {
                            id: seekMa
                            anchors.fill: parent; anchors.margins: -12; cursorShape: Qt.PointingHandCursor
                            onReleased: (mouse) => { if (root.player && root.player.length > 0) { root.player.position = (Math.max(0, Math.min(mouse.x, waveContainer.width)) / waveContainer.width) * root.player.length; root.currentPos = root.player.position; } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: root.isActive ? root.formatTime(root.currentPos) : "0:00"; color: "#dddddd"; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
                        Item { Layout.fillWidth: true }
                        Text { text: root.isActive ? root.formatTime(root.player.length) : "0:00"; color: "#dddddd"; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
                    }
                }
            }

            Item { Layout.fillHeight: true; Layout.maximumHeight: 10 }

            RowLayout {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter; spacing: 36; Layout.maximumHeight: 60 

                component CtrlBtn : Text {
                    property bool active: false
                    font.family: "Material Symbols Outlined"; font.pixelSize: 24
                    color: active ? root.dynamicThemeColor : "white"; opacity: active ? 1.0 : 0.7
                    scale: ma.pressed ? 0.8 : (ma.containsMouse ? 1.1 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 150 } }
                    MouseArea { id: ma; anchors.fill: parent; anchors.margins: -10; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.triggered() }
                    signal triggered() 
                }

                CtrlBtn { text: "shuffle"; active: root.player && root.player.shuffle; onTriggered: if(root.player && root.player.shuffleSupported) root.player.shuffle = !root.player.shuffle } 
                CtrlBtn { text: "skip_previous"; onTriggered: if(root.player) root.player.previous() } 
                
                Rectangle {
                    width: 60; height: 60; radius: 30; color: root.dynamicThemeColor 
                    scale: playMa.pressed ? 0.9 : (playMa.containsMouse ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: (root.player && root.player.isPlaying) ? "pause" : "play_arrow"; color: Colorscheme.background; font.family: "Material Symbols Outlined"; font.pixelSize: 28 }
                    MouseArea { id: playMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if(root.player) root.player.togglePlaying() }
                }

                CtrlBtn { text: "skip_next"; onTriggered: if(root.player) root.player.next() } 
                CtrlBtn { 
                    active: root.player && root.player.loopState !== MprisLoopState.None
                    text: (!root.player) ? "repeat" : (root.player.loopState === MprisLoopState.Track ? "repeat_one" : "repeat")
                    onTriggered: {
                        if(!root.player || !root.player.loopSupported) return;
                        if (root.player.loopState === MprisLoopState.None) root.player.loopState = MprisLoopState.Playlist; 
                        else if (root.player.loopState === MprisLoopState.Playlist) root.player.loopState = MprisLoopState.Track; 
                        else root.player.loopState = MprisLoopState.None; 
                    }
                } 
            }
        }
    }
}
