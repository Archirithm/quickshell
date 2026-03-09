import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris
import qs.config 

Item {
    id: root
    
    required property var player
    
    readonly property bool isActive: root.visible && root.player

    property string artUrl: (isActive && player.trackArtUrl) ? player.trackArtUrl : ""
    property string title: (isActive && player.trackTitle) ? player.trackTitle : "No Media"
    property string artist: (isActive && player.trackArtist) ? player.trackArtist : "Unknown Artist"
    property string playerName: (isActive && player.identity) ? player.identity : "Media"
    
    property double currentPos: 0
    Timer {
        interval: 100
        running: root.isActive
        repeat: true
        onTriggered: {
            if (root.player && !seekMa.pressed) {
                root.currentPos = root.player.position;
            }
        }
    }
    
    property double progress: (isActive && player.length > 0) ? (root.currentPos / player.length) : 0

    RowLayout {
        anchors.fill: parent
        // 【核心修复】：移除了 anchors.margins: 20，消除双重边距，彻底释放空间！
        spacing: 24

        // ==========================================
        // 左侧：顶部对齐、重阴影封面
        // ==========================================
        Item {
            Layout.preferredWidth: 120 
            Layout.preferredHeight: 120
            Layout.minimumWidth: 120
            Layout.maximumWidth: 120
            Layout.minimumHeight: 120
            Layout.maximumHeight: 120
            
            Layout.alignment: Qt.AlignTop 
            Layout.topMargin: 2 

            DropShadow {
                anchors.fill: coverContainer
                source: coverContainer
                color: Qt.rgba(0, 0, 0, 0.85) // 极深的透明度
                radius: 24
                samples: 49
                verticalOffset: 8 
            }

            Item {
                id: coverContainer
                anchors.fill: parent

                Rectangle {
                    id: fallbackBg
                    anchors.fill: parent
                    radius: 16 
                    color: Colorscheme.surface_container_high
                    visible: root.artUrl === ""

                    Text {
                        anchors.centerIn: parent
                        text: "🎵"
                        font.pixelSize: 56
                    }
                }

                Image {
                    id: rawImg
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false 
                }

                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: 16
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: rawImg
                    maskSource: maskRect
                    visible: root.artUrl !== "" && rawImg.status === Image.Ready
                }
            }
        }

        // ==========================================
        // 右侧：信息、进度条与控制台
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Text {
                        text: root.title
                        color: Colorscheme.on_surface
                        font.bold: true
                        font.pixelSize: 20
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.artist
                        color: Colorscheme.on_surface_variant
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Item {
                    Layout.preferredWidth: pillRect.width
                    Layout.preferredHeight: pillRect.height
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight

                    DropShadow {
                        anchors.fill: pillRect
                        source: pillRect
                        color: Qt.rgba(0, 0, 0, 0.75)
                        radius: 12
                        samples: 25
                        verticalOffset: 4
                    }

                    Rectangle {
                        id: pillRect
                        width: pillText.width + 24
                        height: 26
                        radius: 13
                        color: Colorscheme.surface_container_highest

                        Text {
                            id: pillText
                            anchors.centerIn: parent
                            text: root.playerName
                            color: Colorscheme.on_surface
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true } // 弹性占位符

            Item {
                id: waveContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                
                property real currentX: root.progress * waveContainer.width
                property real activeX: seekMa.pressed ? Math.max(0, Math.min(seekMa.mouseX, waveContainer.width)) : currentX

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 6
                    radius: 3
                    color: Colorscheme.surface_variant
                }

                Canvas {
                    id: waveCanvas
                    anchors.left: parent.left
                    width: Math.max(6, waveContainer.activeX) 
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    
                    property real phase: 0
                    NumberAnimation on phase {
                        loops: Animation.Infinite
                        from: 0
                        to: Math.PI * 2
                        duration: 1200
                        easing.type: Easing.Linear 
                        running: root.isActive && root.player && root.player.isPlaying
                    }
                    
                    onPhaseChanged: requestPaint()
                    Connections {
                        target: waveContainer
                        function onActiveXChanged() { waveCanvas.requestPaint() }
                    }

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        
                        let trackHeight = 6;
                        let radius = 3;
                        let centerY = height / 2;
                        
                        let w = width; 
                        if (w < radius * 2) return;

                        ctx.beginPath();
                        ctx.moveTo(w, centerY + trackHeight/2);
                        ctx.lineTo(radius, centerY + trackHeight/2);
                        ctx.arcTo(0, centerY + trackHeight/2, 0, centerY, radius);
                        ctx.arcTo(0, centerY - trackHeight/2, radius, centerY - trackHeight/2, radius);
                        
                        let freq1 = 0.05;
                        let maxAmp = 6; 
                        let fadeLen = 30; 
                        
                        for (let x = radius; x <= w; x++) {
                            let leftDist = x - radius;
                            let rightDist = w - x;
                            let envelope = 1.0;
                            
                            if (leftDist < fadeLen) {
                                envelope = Math.sin((leftDist / fadeLen) * (Math.PI / 2));
                            }
                            if (rightDist < fadeLen) {
                                let envRight = Math.sin((rightDist / fadeLen) * (Math.PI / 2));
                                if (envRight < envelope) envelope = envRight;
                            }
                            
                            let wave1 = Math.sin(x * freq1 - phase);
                            let wave2 = Math.sin(x * freq1 * 1.5 - phase * 2.0) * 0.3;
                            
                            let combined = (wave1 + wave2 + 1.3) / 2.6;
                            if (combined < 0) combined = 0;
                            if (combined > 1) combined = 1;
                            
                            let y = (centerY - trackHeight/2) - (combined * maxAmp * envelope);
                            ctx.lineTo(x, y);
                        }
                        
                        ctx.lineTo(w, centerY - trackHeight/2);
                        ctx.lineTo(w, centerY + trackHeight/2);
                        ctx.closePath();
                        
                        ctx.fillStyle = String(Colorscheme.primary);
                        ctx.fill();
                    }
                }

                Rectangle {
                    id: progressThumb
                    width: 14
                    height: 14
                    radius: 7
                    color: Colorscheme.primary
                    anchors.verticalCenter: parent.verticalCenter
                    x: waveContainer.activeX - width/2
                    
                    Behavior on x {
                        enabled: !seekMa.pressed
                        SmoothedAnimation { velocity: 400; duration: 300 }
                    }
                }

                MouseArea {
                    id: seekMa
                    anchors.fill: parent
                    anchors.margins: -10 
                    cursorShape: Qt.PointingHandCursor
                    onReleased: (mouse) => {
                        if (root.player && root.player.length > 0) {
                            let clampedX = Math.max(0, Math.min(mouse.x, waveContainer.width));
                            let targetPos = (clampedX / waveContainer.width) * root.player.length;
                            root.player.position = targetPos;
                            root.currentPos = targetPos;
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 40 

                component CtrlBtn : Text {
                    property bool active: false
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 26 
                    color: active ? Colorscheme.primary : Colorscheme.on_surface
                    opacity: active ? 1.0 : 0.7
                    scale: ma.pressed ? 0.8 : (ma.containsMouse ? 1.1 : 1.0)
                    
                    Behavior on scale { NumberAnimation { duration: 150 } }
                    
                    MouseArea { 
                        id: ma
                        anchors.fill: parent
                        anchors.margins: -10
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.triggered() 
                    }
                    signal triggered() 
                }

                CtrlBtn { 
                    text: "shuffle"
                    active: root.player && root.player.shuffle
                    onTriggered: if(root.player && root.player.shuffleSupported) root.player.shuffle = !root.player.shuffle 
                } 
                
                CtrlBtn { 
                    text: "skip_previous"
                    font.pixelSize: 32
                    onTriggered: if(root.player) root.player.previous() 
                } 
                
                Rectangle {
                    width: 54 
                    height: 54
                    radius: 27
                    color: Colorscheme.primary 
                    scale: playMa.pressed ? 0.9 : (playMa.containsMouse ? 1.05 : 1.0)
                    
                    Behavior on scale { NumberAnimation { duration: 150 } }
                    
                    Text { 
                        anchors.centerIn: parent
                        text: (root.player && root.player.isPlaying) ? "pause" : "play_arrow"
                        color: Colorscheme.on_primary
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 34 
                    }
                    
                    MouseArea { 
                        id: playMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if(root.player) root.player.togglePlaying() 
                    }
                }

                CtrlBtn { 
                    text: "skip_next"
                    font.pixelSize: 32
                    onTriggered: if(root.player) root.player.next() 
                } 
                
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
