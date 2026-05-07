import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Common
import qs.Services
import qs.Widgets.common

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
    // 歌词抓取与解析引擎
    // ==========================================
    ListModel { id: lyricsModel }
    
    Process {
        id: lyricsProc
        running: false
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
        property color extractedColor: Appearance.colors.colPrimary

        Connections {
            target: root
            function onArtUrlChanged() {
                if (root.artUrl !== "") colorExtractor.loadImage(root.artUrl);
                else colorExtractor.extractedColor = Appearance.colors.colPrimary;
            }
        }
        onImageLoaded: {
            var ctx = getContext("2d");
            ctx.drawImage(root.artUrl, 0, 0, 1, 1);
            var imgData = ctx.getImageData(0, 0, 1, 1).data;
            
            var r = imgData[0] / 255.0;
            var g = imgData[1] / 255.0;
            var b = imgData[2] / 255.0;
            var baseColor = Qt.rgba(r, g, b, 1.0);
            var h = baseColor.hslHue;
            var s = baseColor.hslSaturation;
            var l = baseColor.hslLightness;
            
            s = Math.min(1.0, s * 1.5);
            if (s < 0.1) {
                extractedColor = Appearance.colors.colPrimary;
            } else {
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
            if (root.player && !mediaProgress.pressed) {
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
        
        anchors.topMargin: 5
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        anchors.bottomMargin: 25 
 
        radius: 24 
        color: Appearance.colors.colLayer1

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: mainBg.width
                height: mainBg.height
                radius: mainBg.radius
            }
        }

        Item {
            anchors.fill: parent
            clip: true

            Image {
                id: bgSource
                anchors.centerIn: parent
                width: parent.width * 1.5
                height: parent.height * 1.5
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            MultiEffect {
                anchors.fill: bgSource
                source: bgSource
                visible: root.artUrl !== ""
                blurEnabled: true
                blur: 1.0
                blurMax: 80
                contrast: 0.2
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
            }
        }

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
                color: root.showLyrics ? Appearance.colors.colLayer0 : "white"
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.showLyrics = !root.showLyrics }
        }

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
                        let baseRadius = 72;
                        let maxAmp = 25; 
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

            ColumnLayout {
                id: infoContainer
                width: parent.width
                x: 0
                y: coverContainer.y + coverContainer.height - 8
                spacing: 2 

                Text { text: root.title; color: "white"; font.pixelSize: 20; font.bold: true; Layout.alignment: Qt.AlignHCenter; elide: Text.ElideRight; Layout.maximumWidth: root.width - 80 }
                Text { text: root.artist; color: "#cccccc"; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter; elide: Text.ElideRight; Layout.maximumWidth: root.width - 80 }
                Text { text: root.album; color: "#888888"; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter; elide: Text.ElideRight; Layout.maximumWidth: root.width - 80 }
            }

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
                        font.pixelSize: 18
                        font.bold: true 
                        opacity: ListView.isCurrentItem ? 1.0 : 0.5
                        transformOrigin: Item.Left
                        scale: ListView.isCurrentItem ? 1.25 : 1.0
                        horizontalAlignment: Text.AlignLeft
                        wrapMode: Text.WordWrap
                        
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

                    MaterialWaveProgressBar {
                        id: mediaProgress
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        progress: root.realProgress
                        waveColor: root.dynamicThemeColor
                        trackColor: root.dynamicThemeColor
                        trackOpacity: 0.3
                        isPlaying: root.player ? root.player.isPlaying : false

                        onSeekRequested: (position) => {
                            if (root.player && root.player.length > 0) {
                                root.player.position = position * root.player.length;
                                root.currentPos = root.player.position;
                            }
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

            MediaControlBar {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumHeight: 60
                spacing: 36
                isPlaying: root.player ? root.player.isPlaying : false
                shuffleActive: root.player && root.player.shuffle
                shuffleEnabled: root.player && root.player.shuffleSupported
                previousEnabled: root.player
                playPauseEnabled: root.player
                nextEnabled: root.player
                loopEnabled: root.player && root.player.loopSupported
                loopMode: !root.player || root.player.loopState === MprisLoopState.None
                    ? 0
                    : (root.player.loopState === MprisLoopState.Track ? 2 : 1)
                activeColor: root.dynamicThemeColor
                inactiveColor: "white"
                iconSize: 24
                skipIconSize: 24
                inactiveOpacity: 0.7
                disabledOpacity: 0.35
                playingBg: root.dynamicThemeColor
                playingFg: Appearance.colors.colLayer0
                pausedBg: root.dynamicThemeColor
                pausedFg: Appearance.colors.colLayer0
                playButtonSize: 60
                playIconSize: 28
                playPressedScale: 0.9
                playHoverScale: 1.05
                morphEnabled: true

                onShuffleClicked: if (root.player && root.player.shuffleSupported) root.player.shuffle = !root.player.shuffle
                onPreviousClicked: if (root.player) root.player.previous()
                onPlayPauseClicked: if (root.player) root.player.togglePlaying()
                onNextClicked: if (root.player) root.player.next()
                onLoopClicked: {
                    if (!root.player || !root.player.loopSupported)
                        return;
                    if (root.player.loopState === MprisLoopState.None)
                        root.player.loopState = MprisLoopState.Playlist;
                    else if (root.player.loopState === MprisLoopState.Playlist)
                        root.player.loopState = MprisLoopState.Track;
                    else
                        root.player.loopState = MprisLoopState.None;
                }
            }
        }
    }
}
